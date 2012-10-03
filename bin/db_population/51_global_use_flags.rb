#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'
require 'parser'

def get_data(params)
    file_content = IO.read('/etc/make.conf').split("\n")
    Parser.get_multi_line_ini_value(file_content, 'USE').split.uniq
end

class Script
    SOURCE = '/etc/make.conf'
    TYPE = 'global'

    def pre_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, SOURCE)
        @shared_data['source@id'] = { SOURCE => source_id }

        type_id = Database.get_1value(UseFlag::SQL['type'], TYPE)
        @shared_data['type@id'] = { TYPE => type_id }

        sql_query = 'select state, id from flag_states;'
        @shared_data['state@id'] = Hash[Database.select(sql_query)]

        sql_query = 'select name, id from flags where type_id = ?;'
        @shared_data['flag@id'] = {TYPE => Hash[Database.select(sql_query, type_id)]}
    end

    def process(flag_spec)
        flag = UseFlag.get_flag(flag_spec)
        flag_id = @shared_data['flag@id'][TYPE][flag]
        # we have to use different method for getting state of flag
        # because of https://github.com/zvasyl/portage3/wiki/Collisions-in-Gentoo
        flag_state = UseFlag.get_flag_state2(flag_spec)
        flag_state_id = @shared_data['state@id'][flag_state]
        source_id = @shared_data['source@id'][SOURCE]
        Database.add_data4insert(flag_id, flag_state_id, source_id)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO flags_states
        (flag_id, state_id, source_id)
        VALUES (?, ?, ?);
    SQL
})

