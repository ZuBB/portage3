#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/03/12
# Latest Modification: Vasyl Zuzyak, ...
#

class Ebuild
    private
    def get_cache_value
        line = ebuild_cache.select { |line| line.start_with?(@curr_prop) }
        #return "0_" + @curr_prop + "_DEF" if line.empty?
        return "" if line.empty?
        if line.size == 1
            line[0].split('=')[1].strip
        else
            
        end
    end

    def get_ini_value
        ebuild_text = @ebuild_text.clone

        begin
            prop_value = Parser.get_multi_line_ini_value(ebuild_text, @curr_prop)
            prop_value = Parser.extract_sub_value(ebuild_text, prop_value, create_predefined_vars)

            # if we did not find anything
            if prop_value.start_with?('0_')
                # lets try to get data from 'inherit' stuff
                prop_value = get_inherited_value(prop_value)
            end

            # if we still have '_DEF' at the end
            if prop_value.end_with?('_DEF') && @curr_prop != 'EAPI'
                # lets get data from via portageq command
                # TODO should we remove this 'if'?
                #prop_value = get_portageq_value(prop_value)
            end
        rescue Exception => exception
            PLogger.fatal("Got runtime error while parsing ebuild")
            PLogger.fatal("Message: #{exception.message}")
            PLogger.fatal("Backtrace: \n#{exception.backtrace.join("\n")}")
        end

        if prop_value.include?(@curr_prop + '_DEF')
            if @curr_prop != 'EAPI'
                message = "Found next value (#{prop_value}) for #{@curr_prop}"
                PLogger.warn(message)
            else
                #prop_value = '0' 
            end
        end

        cleanup_value(prop_value)
    end

    def create_predefined_vars
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

    def get_inherited_eclasses
        @ebuild_eclasses = []

        # lets find line with "inherit" keyword
        # TODO replace 'index' with regexp?
        lines = @ebuild_text.select { |line| line.index('inherit') == 0 }

        lines.each do |line|
            # lets get all items(eclasses) that is inherited
            inherit_items = line.split(' ')
            # drop inherit keyword
            inherit_items.shift
            @ebuild_eclasses += inherit_items
        end
    end

    def inherit_exception?
        forbidden_inheritance = ['eapi']
        forbidden_inheritance.include?(@curr_prop.downcase)
    end

    def get_inherited_value(old_value)
        # lets process exceptions
        return old_value if inherit_exception?

        # lets get all eclasses that is inherited
        get_inherited_eclasses if @ebuild_eclasses.nil?

        # lets find eclass that is most related to this category&package
        inherit_items = find_related_eclass

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

    def find_related_eclass
        # clone original array
        eclasses = @ebuild_eclasses.clone

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
        return %x[#{command}].strip
    end
end

