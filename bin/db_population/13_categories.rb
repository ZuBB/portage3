#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'category'

class Script
    SOURCE = 'profiles'

    def pre_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, SOURCE)
        @shared_data['source@id'] = { SOURCE => source_id }
    end

    def process(params)
        PLogger.debug("Category: #{params}")
        category = Category.new(params)

        params = [category.category]
        params << category.category_description
        params << @shared_data['source@id'][SOURCE]

        Database.add_data4insert(params)
    end
end

script = Script.new({
    'data_source' => Category.method(:get_categories),
    'sql_query' => <<-SQL
        INSERT INTO categories
        (name, descr, source_id)
        VALUES (?, ?, ?);
    SQL
})

