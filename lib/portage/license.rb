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
        if /\n/ =~ licenses
            PLogger.warn("newline")
        end

        if licenses.include?('?')
            self.extract_0dep_licenses(licenses)
        else
            licenses
        end
    end

    def self.extract_0dep_licenses(licenses)
        ''
    end
end

