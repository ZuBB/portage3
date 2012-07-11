#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'
require 'category'

def process(params)
    PLogger.info("Category: #{params['value']}")
    category = Category.new(params)

    Database.add_data4insert(
        [category.category(), category.category_description()]
    )
end

script = Script.new({
    'thread_code' => method(:process),
    'data_source' => Category.method(:get_categories),
    'sql_query' => 'INSERT INTO categories (category_name, description) VALUES (?, ?);'
})

