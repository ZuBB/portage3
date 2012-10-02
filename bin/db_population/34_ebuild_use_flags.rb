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
        # NOTE we need here `.uniq()` because results of command like this
        # `portageq metadata / ebuild www-client/firefox-10.0.5 IUSE`
        # may return duplicated flags.
        # I did not make any checks on state of the flag that is being returned
        ebuild.ebuild_use_flags.split.uniq.each do |flag|
            params =  [UseFlag.get_flag(flag)]
            params << ebuild.package_id
            params << @shared_data['state@id'][UseFlag.get_flag_state(flag)]
            params << ebuild.ebuild_id
            params << @shared_data['source@id']['ebuilds']
            Database.add_data4insert(params)
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
                WHERE
                    name=? AND
                    (
                        -- case for local flag
                        package_id = ? OR
                        -- case for flag of all another types (except unknown)?
                        (package_id IS NULL)
                    )
                ORDER BY type_id ASC
                LIMIT 1
            ),
            ?,
            ?,
            ?
        );
    SQL
})

