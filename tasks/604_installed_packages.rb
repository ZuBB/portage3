#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '152_profile_categories;603_installed_packages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO categories (name, source_id) VALUES (?, ?);
        SQL
    }

    def get_data(params)
        sql_query = Category::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_installed_packages_categories')
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)
