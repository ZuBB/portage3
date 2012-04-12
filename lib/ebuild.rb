#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/03/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'package' unless Object.const_defined?(:Package)
require 'parser' unless Object.const_defined?(:Parser)

class Ebuild < Package
    PORTAGEQ = !%x[whereis portageq].split(':')[1].match(/\S+/).nil?
    SQL = {
        "eapi_id" => "SELECT id FROM eapis WHERE eapi_version=?",
        "ebuild_id" => "SELECT id FROM ebuilds \
                        WHERE package_id=? AND version=?"
    }

    def initialize(params, strict = true)
        # call init of superclass
        super(params)

        # assign some default values
        @ebuild_text = []
        @filename = ''
        @VERSION = ''

        # check if everything is OK
        if is_file_invalid?(params["filename"])
            if strict
                throw "Can not process `#{params["filename"]}` file"
            else
                PLogger.warn("Is there any ebuilds for #{@CATEGORY}/#{@PACKAGE}?")
            end
        end

        # continue assign some default values
        set_props_filename_dependant(params["filename"]) if params["filename"]
        @inherited_eclasses = nil
        @parse_errors = []
        @curr_prop = nil

        @DESCRIPTION = nil
        @HOMEPAGE = nil
        @LICENSES = []
        @EAPI = nil
        @SLOT = nil
        @IUSE = nil

        @author = nil
        @mtime = nil
        @ebuild_id = nil
        @eapi_id = nil
    end

    def ebuild_id()
        return @ebuild_id ||= get_ebuild_id()
    end

    def version()
        return @VERSION
    end

    def mtime()
        return @mtime ||= get_mtime()
    end

    def author()
        return @author ||= get_author()
    end

    def description(method = nil)
        get_value('DESCRIPTION', method)
    end

    def keywords(method = nil)
        get_value('KEYWORDS', method)
    end

    def homepage(method = nil)
        # Quoting page from devmanual
        # http://devmanual.gentoo.org/ebuild-writing/variables/index.html

        # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        # Never refer to a variable name in the string;
        # include only raw text
        # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        get_value('HOMEPAGE', method)
    end

    def license(method = nil)
        get_value('LICENSE', method)
    end

    def slot(method = nil)
        # http://devmanual.gentoo.org/general-concepts/slotting/index.html
        get_value('SLOT', method)
    end

    def use_flags(method = nil)
        get_value('IUSE', method)
    end

    def eapi(method = nil)
        # http://devmanual.gentoo.org/ebuild-writing/eapi/index.html
        get_value('EAPI', method)
    end

    def eapi_id()
        @eapi_id ||= get_eapi_id()
    end

    private
    def is_file_invalid?(filename)
        return false if filename.nil?
        return false if filename.empty?
        return false if !File.exist?(filename)
        return false if filename[-7..-1] != ".ebuild"
        return false if filename.size < 300
    end

    def set_props_filename_dependant(filename)
        @filename = filename
        @ebuild_text = IO.read(@filename).to_a
        @VERSION = @filename.split('/')[-1][@PACKAGE.size + 1..-8]
    end

    def get_value(prop_name, method)
        # get value of the processed property
        method ||= @method
        # get value of the processed property
        prop_value = self.instance_variable_get('@' + (@curr_prop = prop_name))

        # if value not a nil - return it
        return prop_value unless prop_value.nil?

        # set value of the processed property
        prop_value = method == "parse" ? get_ini_value() : get_portageq_value()

        # set value of the processed property
        self.instance_variable_set('@' + prop_name, prop_value)
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
        @parse_errors << prop_value if prop_value.include?(@curr_prop + '_DEF')

        # cleanup value
        cleanup_value(prop_value)
    end

    def create_predefined_vars()
        # list of predefined variables
        # http://devmanual.gentoo.org/ebuild-writing/variables/index.html

        r_index = @VERSION.rindex('-r') || 0
        upstream_version = @VERSION[0..r_index - 1] || ''
        versions_revision = r_index == 0 ? 'r0' : @VERSION[r_index + 1..-1]

        {
            "P"   => @PACKAGE + '-' + upstream_version,
            "PN"  => @PACKAGE,
            "PV"  => upstream_version,
            "PR"  => versions_revision,
            "PVR" => upstream_version + '-' + versions_revision,
            "PF"  => @PACKAGE + '-' + @VERSION,
        }
    end

    def cleanup_value(prop_value)
        # aii stuff in thi func is a bit workaround
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
        @inherited_eclasses = []

        # lets find line with "inherit" keyword
        # TODO replace 'index' with regexp?
        lines = @ebuild_text.select { |line| line.index('inherit') == 0 }

        lines.each do |line|
            # lets get all items(eclasses) that is inherited
            inherit_items = line.split(' ')
            # drop inherit keyword
            inherit_items.shift()
            @inherited_eclasses += inherit_items
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
        get_inherited_eclasses() if @inherited_eclasses.nil?

        # lets find eclass that is most related to this category&package
        inherit_items = find_related_eclass()

        # TODO ugly hack
        inherit_items = ["gst-plugins10"] if @PACKAGE.index("gst-plugins") == 0

        eclass_filename = inherit_items.to_s + '.eclass'
        eclass_full_path = File.join(@portage_home, 'eclass', eclass_filename)
        eclass_content = IO.read(eclass_full_path).to_a rescue []
        result = Parser.get_multi_line_ini_value(eclass_content, @curr_prop)

        return result || old_value
    end

    def find_related_eclass()
        # clone original array
        eclasses = @inherited_eclasses.clone()

        blacklisted_eclasses = [
            "eutils", "multilib", "toolchain-funcs", "versionator",
            "virtualx", "autotools", "pam", "flag-o-matic", "confutils"
        ]

        # drop blacklisted eclasses
        eclasses.delete_if { |eclass| blacklisted_eclasses.include?(eclass) }

        # match based on lang
        if @CATEGORY.start_with?("dev-")
            lang = @CATEGORY.split('-')[1]
            eclasses.each { |eclass|
                return [eclass] if eclass.start_with?(lang) && lang != eclass
            }
        end

        # package name contains eclass
        eclasses.each { |eclass|
            return [eclass] if @PACKAGE.include?(eclass)
        }

        # category name contains eclass
        eclasses.each { |eclass|
            return [eclass] if @CATEGORY.include?(eclass)
        }

        return eclasses.size == 1 ? eclasses : []
    end

    def get_portageq_value(old_value = "")
        # fallback to old value if required things are missed
        return old_value if !PORTAGEQ || @VERSION.empty?

        # assigns
        atom = "#{@CATEGORY}/#{@PACKAGE}-#{@VERSION}"
        command = "portageq metadata / ebuild #{atom} #{@curr_prop}"
        PLogger.warn("Running portageq to get a #{@curr_prop} for #{atom}")
        # run && get output && return it
        return %x[#{command}].strip()
    end

    def get_ebuild_id()
        Database.get_1value(SQL["ebuild_id"], [package_id(), @VERSION])
    end

    def get_eapi_id()
        @EAPI = 0 if eapi().end_with?('_DEF')
        Database.get_1value(SQL["eapi_id"], [@EAPI])
    end

    def get_mtime()
        result = Parser.get_value_from_cvs_header(@ebuild_text, 'mtime')
        result.include?('MTIME') == false ?
            (Time.parse(result).to_i rescue 'NAN_MTIME_DEF') : result
    end

    def get_author()
        Parser.get_value_from_cvs_header(@ebuild_text, "author")
    end
end
