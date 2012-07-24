#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/03/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'package'
require 'package'
require 'parser'

class Ebuild < Package
    ENTITY = self.name.downcase
    PROP_SUFFIXES = [
        'text', 'version', 'description', 'homepage', 'licences', 'eapi',
        'slot', 'author', 'mtime', 'eapi_id', 'eclasses', 'parse_method',
        'iuse'
    ]
    SQL = {
        "eapi_id" => "SELECT id FROM eapis WHERE eapi_version=?",
        "id" => "SELECT id FROM ebuilds WHERE package_id=? AND version=?"
    }

    def initialize(params, strict = true)
        super(params)

        @cur_entity = ENTITY
        create_properties(PROP_SUFFIXES)
        gp_initialize(params)
        db_initialize(params)

        # TODO make this ondemand
        load_ebuild_content()
        @ebuild_parse_method = params['method'] || 'parse'
        @curr_prop = nil
    end

    def ebuild_id()
        @ebuild_id ||= Database.get_1value(SQL["id"],
										   package_id,
										   ebuild_version
										  )
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

    def ebuild_licences(method = nil)
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
        set_prop(IO.read(File.join(package_home, @ebuild)).split("\n"), 'text')
    end

    private
    def get_prop(suffix = nil, entity = nil)
        prop_name = (entity || @cur_entity).dup

        unless prop_name.empty?
            prop_name += ('_' + suffix) if suffix.is_a?(String)
            self.instance_variable_get('@' + prop_name)
        end
    end

    def set_prop(value = nil, suffix = nil, entity = nil)
        prop_name = (entity || @cur_entity).dup

        unless prop_name.empty?
            prop_name += ('_' + suffix) if suffix.is_a?(String)
            self.instance_variable_set('@' + prop_name, value)
        end
    end

    def get_value(prop_name, method)
        # get method
        method ||= @ebuild_parse_method
        # get value of the processed property
        prop_value = get_prop(prop_name)
        @curr_prop = prop_name.clone.upcase

        # if value not a nil - return it
        return prop_value unless prop_value.nil?

        # set value of the processed property
        prop_value = method == "parse" ? get_ini_value : get_portageq_value

        # set value of the processed property
        set_prop(prop_value, prop_name)
        # now we stopping its processing
        @curr_prop = nil
        # return it
        return prop_value
    end

    def get_ini_value()
        # copy ebuild content
        ebuild_text = @ebuild_text.clone

        begin
            # lets try plain parse
            prop_value = Parser.get_multi_line_ini_value(ebuild_text,
														 @curr_prop
														)

            # check for subvalues and if so - try to replace them
            prop_value = Parser.extract_sub_value(ebuild_text,
												  prop_value,
												  create_predefined_vars
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
        if !Utils::SETTINGS['gentoo_os'] || ebuild_version.empty?
            return old_value
        end

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

    def self.list_ebuilds(params = {})
        results = []
        sql_query = <<-SQL
            SELECT c.category_name, p.package_name, p.id
            FROM packages p
            JOIN categories c on p.category_id = c.id;
        SQL

        atoms = Database.select(sql_query)

        Database.select(Repository::SQL['all']).each do |repo_row|
            repo_home = File.join(repo_row[2], repo_row[3] || repo_row[1])
            next unless File.exist?(repo_home)

            atoms.each do |atom_row|
                package_home = File.join(repo_home, atom_row[0], atom_row[1])
                next unless File.exist?(package_home)

                Dir.glob(File.join(package_home, '*ebuild')).each do |ebuild|
                    results << {
                        'ebuild'        => ebuild[ebuild.rindex('/') + 1..-1],
                        'package'       => atom_row[1],
                        'package_id'    => atom_row[2],
                        'category'      => atom_row[0],
                        'repository'    => repo_row[1],
                        'repository_id' => repo_row[0],
                        'repository_pd' => repo_row[2],
                        'repository_fs' => repo_row[3] || repo_row[1]
                    }
                end
            end
        end

        results
    end

    def self.get_ebuilds(params = {})
        Database.select(<<-SQL
            SELECT
                repository_name,
                parent_folder,
                repository_folder,
                category_name,
                package_name,
                version,
                e.id,
                e.package_id
            FROM ebuilds e
            JOIN packages p on p.id=e.package_id
            JOIN categories c on p.category_id=c.id
            JOIN repositories r on r.id=e.repository_id
        SQL
        )
    end

    def self.generate_ebuild_params(params)
        {
            'repository'     => params[0],
            'repository_pd'  => params[1],
            'repository_fs'  => params[2],
            'category'       => params[3],
            'package'        => params[4],
            'ebuild_version' => params[5],
            'ebuild_id'      => params[6],
            'ebuild'         => params[4] + '-' + params[5] + '.ebuild'
        }
    end
end

