#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'installed_package'
require 'useflag'

class Script
    def pre_insert_task
        sql_query = 'select state, id from flag_states;'
        @shared_data['state@id'] = Hash[Database.select(sql_query)]
    end

    def process(param)
        iebuild_id = param[0]

        return unless (file = InstalledPackage.get_file(param, 'USE'))

        IO.read(file).split.each do |flag|
            flag_name = UseFlag.get_flag(flag)
            flag_state = UseFlag.get_flag_state(flag)
            flag_state_id = @shared_data['state@id'][flag_state]
            Database.add_data4insert(iebuild_id, flag_name, flag_state_id)
        end
    end
end

script = Script.new({
    'data_source' => InstalledPackage.method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO package_flagstates
        (iebuild_id, flag_id, state_id)
        VALUES (
            ?,
            (
                SELECT id
                FROM flags
                WHERE name=?
                ORDER BY type_id ASC
                LIMIT 1
            ),
            ?
        );
    SQL
})

