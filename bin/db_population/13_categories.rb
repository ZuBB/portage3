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
    def process(params)
        PLogger.debug("Category: #{params}")
        category = Category.new(params)

        Database.add_data4insert(category.category,
                                 category.category_description
                                )
    end
end

script = Script.new({
    'data_source' => Category.method(:get_categories),
    'sql_query' => <<-SQL
        INSERT INTO categories
        (category_name, description)
        VALUES (?, ?);
    SQL
})

