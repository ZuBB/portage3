#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '632_package_flagstates'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ipackage_flagstates
            (iebuild_id, state_id, flag_id)
            VALUES (?, ?, (
                    SELECT id
                    FROM flags
                    WHERE name=?
                    ORDER BY type_id ASC
                    LIMIT 1
            ));
        SQL
    }

    def get_data(params)
        InstalledPackage.get_data(params)
    end

    def set_shared_data
        request_data('state@id', UseFlag::SQL['@2'])
    end

    def process_item(param)
        # https://www.linux.org.ru/forum/general/8072082?cid=8080127
        InstalledPackage.get_file_lines(param, 'USE').to_a.join('').split
        .each do |flag|
            send_data4insert([
                param[0],
                shared_data('state@id', UseFlag.get_flag_state(flag)),
                UseFlag.get_flag(flag)
            ])
        end
    end
end

Tasks.create_task(__FILE__, klass)
