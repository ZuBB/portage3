#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/03/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'common'))
require 'repository_module'
require 'category_module'
require 'package_module'
require 'fsobject'
require 'parser'

module EbuildModule
    include FSobject
    include RepositoryModule
    include CategoryModule
    include PackageModule

    # constants
    # name of the entity
    ENTITY = self.name.downcase[0..-7]
    # suffixes
    PROP_SUFFIXES = [
        'text', 'version', 'description', 'homepage', 'licenses', 'eapi',
        'slot', 'author', 'mtime', 'eapi_id', 'eclasses', 'parse_method',
        'iuse'
    ]
    # PORTAGEQ
    PORTAGEQ = !%x[whereis portageq].split(':')[1].match(/\S+/).nil?
    # sql stuff
    SQL = {
        "eapi_id" => "SELECT id FROM eapis WHERE eapi_version=?",
        "id" => "SELECT id FROM ebuilds \
                        WHERE package_id=? AND version=?"
    }

    def ebuild_init(params)
        # fix ff
        params = Routines.fix_params(params, ENTITY != self.class.name.downcase)

        # create 'system' properties for repository (sub)object
        self.create_properties(
            ENTITY, Routines.get_module_suffixes() + PROP_SUFFIXES
        )

        # run inits for all kind of modules that we need to inherit
        self.gp_initialize(params)
        self.db_initialize(params)
        self.fs_initialize(params)

        # run init for package stuff
        self.package_init(params)
        # run init for repository stuff
        self.repository_init(params)

        # assign some default values
        @cur_entity = ENTITY
        self.load_ebuild_content()
        @ebuild_parse_method = params['method'] || 'parse'
        @curr_prop = nil
    end

    def ebuild_id()
        @ebuild_id ||= Database.get_1value(SQL["id"], [package_id, ebuild_version])
    end

    def ebuild_version()
        @ebuild_version ||= @ebuild[@package.size + 1..-8]
    end

    def ebuild_mtime()
        @mtime ||= Time.parse(
            Parser.get_value_from_cvs_header(@ebuild_text, 'mtime')
        ).to_i rescue 'NAN_MTIME_DEF'
    end

    def ebuild_author()
        @author ||= Parser.get_value_from_cvs_header(@ebuild_text, "author")
    end

    def ebuild_description(method = nil)
        get_value('description', method)
    end

    def ebuild_keywords(method = nil)
        get_value('keywords', method)
    end

    def ebuild_homepage(method = nil)
        # http://devmanual.gentoo.org/ebuild-writing/variables/index.html
        get_value('homepage', method)
    end

    def ebuild_license(method = nil)
        get_value('license', method)
    end

    def ebuild_slot(method = nil)
        # http://devmanual.gentoo.org/general-concepts/slotting/index.html
        get_value('slot', method)
    end

    def ebuild_use_flags(method = nil)
        get_value('iuse', method)
    end

    def ebuild_eapi(method = nil)
        # http://devmanual.gentoo.org/ebuild-writing/eapi/index.html
        get_value('eapi', method)
    end

    def ebuild_eapi_id()
        @ebuild_eapi_id ||= get_eapi_id()
    end

    def load_ebuild_content()
        self.set_prop(IO.read(File.join(@ebuild_pd, @ebuild)).to_a, 'text')
    end

    private
    def is_file_invalid?(filename)
        return false if filename.nil?
        return false if filename.empty?
        return false if !File.exist?(filename)
        return false if filename[-7..-1] != ".ebuild"
        return false if filename.size < 300
    end

    def get_value(prop_name, method)
        # get method
        method ||= @ebuild_parse_method
        # get value of the processed property
        prop_value = self.get_prop(prop_name)
        @curr_prop = prop_name.clone.upcase

        # if value not a nil - return it
        return prop_value unless prop_value.nil?

        # set value of the processed property
        prop_value = method == "parse" ? get_ini_value() : get_portageq_value()

        # set value of the processed property
        self.set_prop(prop_value, prop_name)
        # now we stopping its processing
        @curr_prop = nil
        # return it
        return prop_value
    end

    def get_ini_value()
        # copy ebuild content
        ebuild_text = @ebuild_text.clone()

        begin
            # lets try plain parse
            prop_value = Parser.get_multi_line_ini_value(ebuild_text, @curr_prop)

            # check for subvalues and if so - try to replace them
            prop_value = Parser.extract_sub_value(
                ebuild_text, prop_value, create_predefined_vars()
            )

            # if we did not find anything
            if prop_value.start_with?('0_')
                # lets try to get data from 'inherit' stuff
                prop_value = get_inherited_value(prop_value)
            end

            # if we still have '_DEF' at the end (this means smth wrong)
            if prop_value.end_with?('_DEF')
                # lets get data from via portageq command
                prop_value = get_portageq_value(prop_value)
            end
        rescue Exception => exception
            PLogger.fatal("Got runtime error while parsing ebuild")
            PLogger.fatal("Message: #{exception.message()}")
            PLogger.fatal("Backtrace: \n#{exception.backtrace.join("\n")}")
        end

        # store this "error"
        if prop_value.include?(@curr_prop + '_DEF')
            PLogger.warn("Failed to find correct value (#{prop_value}) for #{@curr_prop}")
        end

        # cleanup value
        cleanup_value(prop_value)
    end

    def create_predefined_vars()
        # list of predefined variables
        # http://devmanual.gentoo.org/ebuild-writing/variables/index.html

        r_index = ebuild_version.rindex('-r') || 0
        upstream_version = ebuild_version[0..r_index - 1] || ''
        versions_revision = r_index == 0 ? 'r0' : ebuild_version[r_index + 1..-1]

        {
            "P"   => @package + '-' + upstream_version,
            "PN"  => @package,
            "PV"  => upstream_version,
            "PR"  => versions_revision,
            "PVR" => upstream_version + '-' + versions_revision,
            "PF"  => @package + '-' + ebuild_version,
        }
    end

    def cleanup_value(prop_value)
        # all stuff in this func is a bit workaround
        # doing this we just copying portage approach

        # if we have 2+ space symbols in place - lets fix this
        if prop_value.match(/\s{2,}/)
            PLogger.info("Got 2+ spaces in #{@curr_prop}. Fixing..")
            prop_value.gsub!(/\s{2,}/, ' ')
        end

        # if we have escaped quotes - lets fix this
        if prop_value.match(/\\['"]/)
            PLogger.info("Got escaped quotes in #{@curr_prop}. Fixing..")
            prop_value.gsub!(/\\(['"])/, '\1')
        end

        # return fixed value
        return prop_value
    end

    def get_inherited_eclasses()
        @ebuild_eclasses = []

        # lets find line with "inherit" keyword
        # TODO replace 'index' with regexp?
        lines = @ebuild_text.select { |line| line.index('inherit') == 0 }

        lines.each do |line|
            # lets get all items(eclasses) that is inherited
            inherit_items = line.split(' ')
            # drop inherit keyword
            inherit_items.shift()
            @ebuild_eclasses += inherit_items
        end
    end

    def inherit_exception?()
        forbidden_inheritance = ['eapi']
        forbidden_inheritance.include?(@curr_prop.downcase())
    end

    def get_inherited_value(old_value)
        # lets process exceptions
        return old_value if inherit_exception?()

        # lets get all eclasses that is inherited
        get_inherited_eclasses() if @ebuild_eclasses.nil?

        # lets find eclass that is most related to this category&package
        inherit_items = find_related_eclass()

        # TODO ugly hack
        inherit_items = ["gst-plugins10"] if @package.index("gst-plugins") == 0

        eclass_filename = inherit_items.to_s + '.eclass'
        eclass_full_path = File.join(
			@repository_pd, @repository_fs, 'eclass', eclass_filename
		)
        eclass_content = IO.read(eclass_full_path).to_a rescue []
        result = Parser.get_multi_line_ini_value(eclass_content, @curr_prop)

        return result || old_value
    end

    def find_related_eclass()
        # clone original array
        eclasses = @ebuild_eclasses.clone()

        blacklisted_eclasses = [
            "eutils", "multilib", "toolchain-funcs", "versionator",
            "virtualx", "autotools", "pam", "flag-o-matic", "confutils"
        ]

        # drop blacklisted eclasses
        eclasses.delete_if { |eclass| blacklisted_eclasses.include?(eclass) }

        # match based on lang
        if @category.start_with?("dev-")
            lang = @category.split('-')[1]
            eclasses.each { |eclass|
                return [eclass] if eclass.start_with?(lang) && lang != eclass
            }
        end

        # package name contains eclass
        eclasses.each { |eclass|
            return [eclass] if @package.include?(eclass)
        }

        # category name contains eclass
        eclasses.each { |eclass|
            return [eclass] if @category.include?(eclass)
        }

        return eclasses.size == 1 ? eclasses : []
    end

    def get_portageq_value(old_value = "")
        # fallback to old value if required things are missed
        return old_value if !PORTAGEQ || ebuild_version.empty?

        # assigns
        atom = "#{category}/#{package}-#{ebuild_version}"
        command = "portageq metadata / ebuild #{atom} #{@curr_prop}"
        PLogger.warn("Running portageq to get a #{@curr_prop} for #{atom}")
        # run && get output && return it
        return %x[#{command}].strip()
    end

    def get_eapi_id()
        # TODO store_real_eapi(ebuild_obj)
        @ebuild_eapi = 0 if ebuild_eapi().end_with?('_DEF')
        Database.get_1value(SQL["eapi_id"], @ebuild_eapi)
    end
end

