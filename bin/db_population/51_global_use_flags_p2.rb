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
    Parser.get_multi_line_ini_value(file_content, 'USE').split
end

class Script
    SOURCE = '/etc/make.conf'

    def pre_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, SOURCE)
        @shared_data['source@id'] = { SOURCE => source_id }

        sql_query = 'select state, id from flag_states;'
        @shared_data['state@id'] = Hash[Database.select(sql_query)]
    end

    def process(flag)
        flag_id = UseFlag.get_flag(flag)
        flag_name = UseFlag.get_flag(flag)
        flag_state = @shared_data['state@id'][UseFlag.get_flag_state(flag)]
        source_id = @shared_data['source@id'][SOURCE]
        Database.add_data4insert(flag_name, flag_state, source_id)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO flags_states
        (flag_id, state_id, source_id)
        VALUES (
            (SELECT id FROM flags WHERE name=? ORDER BY type_id ASC LIMIT 1),
            ?,
            ?
        );
    SQL
})

