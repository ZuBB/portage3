#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class License
    # http://www.gentoo.org/proj/en/glep/glep-0023.html
    ENTITY = self.name.downcase[0..-7]
    SQL = {
        'group@id' => 'SELECT name, id FROM license_groups;',
        'license@id' => 'SELECT name, id FROM licenses;'
    }
    REGEXPS = {
        'license'  => Regexp.new("^[\\w\\-\\.\\+]+$"),
        'group'  => Regexp.new("^[[:upper:][:digit:]_\\-\\.\\+]+$")
    }

    def self.is_item_valid?(item, type)
        (REGEXPS[type] =~ item) == 0
    end

    def self.is_license_valid?(license)
        self.is_item_valid?(license, 'license')
    end

    def self.is_group_valid?(license)
        self.is_item_valid?(license, 'group')
    end

    def self.get_shared_data
        result = {}

        SQL.each { |key, sql_query|
            result[key] = Hash[Database.select(sql_query)]
        }

        result
    end

    def self.get_0dep_licenses(licenses)
        PLogger.warn("newline") if /\n/ =~ licenses

        # no control chars
        return licenses unless licenses.include?('(')
        # FIXME ugly hack
        return ''
    end
end

