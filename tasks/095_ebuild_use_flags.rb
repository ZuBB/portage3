#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '059_use_flag_stuff;093_read_ebuilds_data'
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
        Ebuild.get_ebuilds_data('use_flags')
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
        request_data('flag_state@id', UseFlag::SQL['@2'])
    end

    def process_item(params)
        @logger.debug("Ebuild: #{params[3, 3].join('-')}")
        # NOTE we need here `.uniq()` because results of command like this
        # `portageq metadata / ebuild www-client/firefox-10.0.10 IUSE`
        # may return duplicated flags.
        params.last.split.uniq.each do |flag|
            send_data4insert({'data' => [
                UseFlag.get_flag(flag),
                params[7],
                shared_data('flag_state@id', UseFlag.get_flag_state(flag)),
                params[6],
                shared_data('source@id', self.class::SOURCE)
            ]})
        end
    end
end

Tasks.create_task(__FILE__, klass)
