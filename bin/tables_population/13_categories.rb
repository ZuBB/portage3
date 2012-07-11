#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
$:.push File.expand_path(File.join(*(lib_path_items + ['portage'])))
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
    'script' => __FILE__, # TODO name it 'parent_script' ?
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO categories (category_name, description) VALUES (?, ?);',
    'data_source' => Category.method(:get_categories)
})

