#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '053_use_flag_basic_stuff;609_installed_packages'
    self::SOURCE = '/var/db/pkg'
    self::TYPE = 'unknown'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_dropped_flags
            (type_id, source_id, name)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        InstalledPackage.get_data(params)
    end

    def set_shared_data
        request_data('flag_type@id', UseFlag::SQL['@1'])
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(param)
        InstalledPackage.get_file_lines(param, 'USE').to_a.join('').split
        .each { |flag|
            send_data4insert([
                shared_data('flag_type@id', self.class::TYPE),
                shared_data('source@id', self.class::SOURCE),
                UseFlag.get_flag(flag)
            ])
        }
    end
end

Tasks.create_task(__FILE__, klass)

