#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class UseFlag
    ENTITY = self.name.downcase[0..-7]
    TYPES = ['unknown', 'arch', 'hidden', 'expand', 'local', 'global']
    STATES = [
        ['unknown', 'unknown'],
        ['masked', 'disabled'],
        ['disabled', 'disabled'],
        ['enabled', 'enabled'],
        ['forced', 'enabled'],
    ]
    SQL = {
        '@1' => 'select type, id from flag_types;',
        '@2' => 'select state, id from flag_states;',
        '@3' => 'select name, id from flags where type_id = ('\
            'select id from flag_types where type = "global"'\
        ');',
        'ghost' => <<-SQL
            SELECT distinct *
            FROM TMP_TABLE tb
            WHERE NOT EXISTS (
                SELECT name FROM flags f WHERE f.name = tb.name
            );
        SQL
    }
    REGEXPS = {
        # app-doc/pms section 8.2
        'state' => Regexp.new('^[\-\+!]{0,2}'),

        # as it turns out these regexps may not work
        # https://bugs.gentoo.org/show_bug.cgi?id=523720
        # besides checks should be happen in other place
        'local'  => Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)"),
        'expand' => Regexp.new('([\\w\\+\\-@]+)(?:\\s+-\\s+)(.*)'),
        'hidden' => Regexp.new('([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)'),
        'global' => Regexp.new('([\\w\\+\\-]+)(?:\\s+-\\s+)(.*)'),
    }

    def self.get_shared_data
        # HINT common code
        # TODO do we need this?
    end

    def self.get_flag(flag)
        flag.sub(REGEXPS['state'], '')
    end

    # used in ebuilds
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

    # used in make.conf
    def self.get_flag_state2(flag)
        sign = REGEXPS['state'].match(flag).to_s
        case sign
        when ''  then 'enabled'
        when '-' then 'disabled'
        else 'unknown'
        end
    end

    # used in use.force
    def self.get_flag_state3(flag)
        case REGEXPS['state'].match(flag).to_s
        when ''  then 'forced'
        # TODO what is the best value for '-' here
        when '-' then 'disabled'
        else 'unknown'
        end
    end

    # used in use.mask
    def self.get_flag_state4(flag)
        case REGEXPS['state'].match(flag).to_s
        when ''  then 'masked'
        when '-' then 'enabled'
        else 'unknown'
        end
    end

    def self.expand_asterix_flag(flags, package_id)
        sql_query = <<-SQL
            select distinct f.name
            from flags f
            join flags_states fs on fs.flag_id = f.id
            join ebuilds e on e.id = fs.ebuild_id
            where e.package_id = ? and (f.type_id BETWEEN 4 and 6);
        SQL
        db_client = Portage3::Database.get_client
        all_flags = db_client.select(sql_query, package_id).flatten

        asterix_index = flags.index { |i| i.include?('*') }
        asterix_flag = flags.delete_at(asterix_index)
        asterix_state = self.get_flag_state(asterix_flag)
        asterix_state_sign = asterix_state == 'disabled' ? '-' : ''

        old_flags = flags.map { |f| self.get_flag(f) }
        new_flags = all_flags - old_flags
        new_flags.map! { |f| f.insert(0, asterix_state_sign) }

        flags.insert(asterix_index, *new_flags)
    end
end

