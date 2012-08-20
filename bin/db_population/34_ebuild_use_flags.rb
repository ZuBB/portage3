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
require 'ebuild'

class Script
    def pre_insert_task
        source = 'ebuilds'
        sql_query = 'select id from sources where source=?;'
        @shared_data['source@id'] = {
            source => Database.get_1value(sql_query, source)
        }

        sql_query = 'select state, id from flag_states;'
        @shared_data['state@id'] = Hash[Database.select(sql_query)]
    end

    def process(params)
        PLogger.debug("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        ebuild.ebuild_use_flags.split.each do |flag|
            flag_name = UseFlag.get_flag(flag)
            flag_state = UseFlag.get_flag_state(flag)
            Database.add_data4insert(flag_name,
                                     @shared_data['state@id'][flag_state],
                                     ebuild.ebuild_id,
                                     @shared_data['source@id']['ebuilds']
                                    )
        end
    end

end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO flags_states
        (flag_id, state_id, ebuild_id, source_id)
        VALUES (
            (
                SELECT id
                FROM flags
                WHERE name=?
                ORDER BY type_id ASC
                LIMIT 1
            ),
            ?,
            ?,
            ?
        );
    SQL
})

