#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'atom'

class Mask
    STATES = ['masked', 'unmasked']
    SQL = {
        '@' => 'SELECT state, id FROM mask_states;'
    }

    def self.parse_line(line)
        result = {}

        # take care about leading '-'
        # it means this atom/package should treated as unmasked
        result["state"] = (line.slice!(/^-/) == '-') ? STATES[1] : STATES[0]

        # take care about trailing ':'
        # it means slot for this atom/package
        result["slot"] = line.slice!(/(?=:).+$/)[1..-1] if line.include?(':')

        # take care about leading ~
        # it means match any subrevision of the specified base version.
        if line.start_with?('~')
            line.sub!(/^~/, '')
            line << '*' unless line.end_with?('*')
        end

        # get version restrictions
        result["vrestr"] = line.slice!(Atom::VERSION_RESTRICTION)

        # get versions
        unless (version = Atom.get_version(line)).nil?
            result["version"] = version
            line.sub!('-' + version, '')
        end

        if result["vrestr"].nil? && /\*$/ =~ result["version"]
            result["vrestr"]  = '='
        end

        result['atom'] = line
        result["category"], result["package"] = *line.split('/')

        result
    end
end

