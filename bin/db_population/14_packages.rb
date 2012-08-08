#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'package'

class Script
    def process(params)
        PLogger.debug("Package: #{params}")
        package = Package.new(params)

        Database.add_data4insert(package.category_id, package.package)
    end
end

script = Script.new({
    'data_source' => Package.method(:get_packages),
    'sql_query' => 'INSERT INTO packages (category_id, name) VALUES (?, ?);'
})

