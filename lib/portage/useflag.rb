#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class UseFlag
    ENTITY = self.name.downcase[0..-7]
    TYPES = ['unknown', 'hidden', 'expand', 'local', 'global']
    STATES = ['masked', 'disabled', 'enabled', 'forced']
    SQL = { 'type' => 'SELECT id FROM flag_types WHERE type=?' }
    REGEXPS = {
        'local'  => Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?:\\s-\\s)(.*)"),
        'expand' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'hidden' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'global' => Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)'),
        'state' => Regexp.new('^[^\\w]?')
    }

    def self.pre_insert_task(type)
        result = {}
        repo = 'gentoo'
        source = 'profiles'

        type_id = Database.get_1value(UseFlag::SQL['type'], type)
        result['flag_type@id'] = { type => type_id }

        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, source)
        result['source@id'] = { source => source_id }

        sql_query = 'SELECT id FROM repositories WHERE name=?;'
        repo_id = Database.get_1value(sql_query, repo)
        result['repo@id'] = { repo => repo_id }

        result
    end

    def self.get_flag(flag)
        flag.sub(REGEXPS['state'], '')
    end

    def self.get_flag_state(flag)
        # app-doc/pms section 8.2
        sign = REGEXPS['state'].match(flag).to_s
        case sign
        when '-' then 'disabled'
        when '+' then 'enabled'
        when '' then 'enabled'
        else nil
        end
    end
end

