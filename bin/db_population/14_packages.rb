#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'
require 'package'

def process(params)
    PLogger.info("Package: #{params["value"]}")
    package = Package.new(params)

    Database.add_data4insert([package.category_id(), package.package()])
end

script = Script.new({
    'thread_code' => method(:process),
    'data_source' => Package.method(:get_packages),
    'sql_query' => 'INSERT INTO packages (category_id, package_name) VALUES (?, ?);'
})

