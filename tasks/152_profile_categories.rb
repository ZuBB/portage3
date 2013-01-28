#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '031_categories;151_profile_categories'
    self::SQL = {
        'insert' => 'INSERT INTO categories (name, source_id) VALUES (?, ?);'
    }

    def get_data(params)
        sql_query = Category::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_profile_categories')
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)

