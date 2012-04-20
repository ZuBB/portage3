#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'package'

script = Script.new({
    "table" => "packages",
    "script" => __FILE__
})

def category_block(params)
    PLogger.info("Category: #{params["category"]}")
    Utils.walk_through_packages({"block2" => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    PLogger.info("Package: #{params["package"]}")
    package = Package.new(Utils.create_ebuild_params(params))

    Database.insert({
        "table" => params["table"],
        "data" => {
            "category_id" => package.category_id(),
            "package_name" => package.package()
        }
    })
end

def fill_table(params)
    Utils.walk_through_categories(
        {"block1" => method(:category_block)}.merge!(params)
    )
end

script.fill_table_X(method(:fill_table))

