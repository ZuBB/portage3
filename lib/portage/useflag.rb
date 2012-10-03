#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class UseFlag
    ENTITY = self.name.downcase[0..-7]
    TYPES = ['unknown', 'hidden', 'expand', 'local', 'global']
    STATES = ['unknown', 'masked', 'disabled', 'enabled', 'forced']
    SQL = { 'type' => 'SELECT id FROM flag_types WHERE type=?' }
    REGEXPS = {
        'local'  => Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)"),
        'expand' => Regexp.new('([\\w\\+\\-@]+)(?:\\s+-\\s+)(.*)'),
        'hidden' => Regexp.new('([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)'),
        'global' => Regexp.new('([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)'),
        # app-doc/pms section 8.2
        'state' => Regexp.new('^[\-\+!]{0,2}')
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
        sign = REGEXPS['state'].match(flag).to_s
        case sign
        # https://www.linux.org.ru/forum/general/8292958?cid=8293106
        when '-' then 'disabled'
        when '+' then 'enabled'
        when ''  then 'disabled'
        else 'unknown'
        end
    end

    def self.get_flag_state2(flag)
        sign = REGEXPS['state'].match(flag).to_s
        case sign
        when ''  then 'enabled'
        when '-' then 'disabled'
        else 'unknown'
        end
    end

    def self.expand_asterix_flag(line, package_id)
        sql_query = <<-SQL
            select distinct f.name
            from flags f
            join flags_states fs on fs.flag_id = f.id
            join ebuilds e on e.id = fs.ebuild_id
            where e.package_id = ?;
        SQL
        all_flags = Database.select(sql_query, package_id).flatten

        flags = line.split.drop(1)

        asterix_index = flags.index { |i| i.include?('*') }
        asterix_flag = flags.delete_at(asterix_index)
        asterix_state = self.get_flag_state(asterix_flag)
        asterix_state_sign = asterix_state == 'disabled' ? '-' : ''

        flag_names = flags.map { |f| self.get_flag(f) }
        new_flags = all_flags - flag_names
        new_flags.map! { |f| f.insert(0, asterix_state_sign) }

        flags.insert(asterix_index, new_flags.join(' ')).join(' ')
    end
end

