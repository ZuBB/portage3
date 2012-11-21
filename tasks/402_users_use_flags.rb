#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '401_users_use_flags'
    self::SOURCE = '/etc/portage'
    self::SQL = {
        'insert' => 'INSERT INTO categories (name, source_id) VALUES (?, ?);'
    }

    def get_data(params)
        sql_query = Category::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_etc_portage_flags_categories')
        Database.select(sql_query).flatten
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
    end

    def process_item(category)
        send_data4insert({'data' => [
            category,
            shared_data('source@id', self.class::SOURCE),
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

