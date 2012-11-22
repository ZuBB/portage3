#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '031_categories;151_profile_masks'
    self::SOURCE = 'profiles'
    self::SQL = {
        'insert' => 'INSERT INTO categories (name, source_id) VALUES (?, ?);'
    }

    def get_data(params)
        sql_query = Category::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_profile_mask_categories')
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

