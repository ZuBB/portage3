#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'ebuild'
require 'source'
require 'useflag'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources;'\
                    '053_global_use_flags;054_local_use_flags;'\
                    '055_expand_use_flags;056_hidden_use_flags;'\
                    '091_ebuilds'
    self::THREADS = 4
    self::SOURCE = 'ebuilds'
    self::SQL = {
        'insert' => <<-SQL
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
    }

    def get_data(params)
        Ebuild.get_ebuilds(params)
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
        Tasks::Scheduler.set_shared_data('flag_state@id', UseFlag::SQL['@2'])
    end

    def process_item(params)
        PLogger.debug(@id, "Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        # NOTE we need here `.uniq()` because results of command like this
        # `portageq metadata / ebuild www-client/firefox-10.0.10 IUSE`
        # may return duplicated flags.
        ebuild.ebuild_use_flags.split.uniq.each do |flag|
            send_data4insert({'data' => [
                UseFlag.get_flag(flag),
                ebuild.package_id,
                shared_data('flag_state@id', UseFlag.get_flag_state(flag)),
                ebuild.ebuild_id,
                shared_data('source@id', self.class::SOURCE)
            ]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

