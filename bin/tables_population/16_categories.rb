#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'category'

script = Script.new({
    "table" => "categories",
    "script" => __FILE__
})

def insert_category(params)
    PLogger.info("Category: #{params["category"]}")
    category = Category.new(Utils.create_ebuild_params(params))

    Database.insert({
        "table" => params["table"],
        "data" => {
            "category_name" => category.category(), 
            "description" => category.category_description()
        }
    })
end

def fill_table(params)
    Utils.walk_through_categories(
        {"block1" => method(:insert_category)}.merge!(params)
    )
end

script.fill_table_X(method(:fill_table))

