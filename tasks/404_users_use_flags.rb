#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'package'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '403_users_use_flags'
    self::SOURCE = '/etc/portage'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO packages
            (name, category_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = Package::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_etc_portage_flags_package')
        Database.select(sql_query)
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
    end

    def process_item(params)
        params << shared_data('source@id', self.class::SOURCE)
        send_data4insert({'data' => params})
    end
end

Tasks.create_task(__FILE__, klass)

