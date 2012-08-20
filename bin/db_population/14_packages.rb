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
    SOURCE = 'profiles'

    def pre_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, SOURCE)
        @shared_data['source@id'] = { SOURCE => source_id }
    end

    def process(params)
        PLogger.debug("Package: #{params}")
        package = Package.new(params)

        params = [package.package]
        params << package.category_id
        params << @shared_data['source@id'][SOURCE]

        Database.add_data4insert(params)
    end
end

script = Script.new({
    'data_source' => Package.method(:get_packages),
    'sql_query' => <<-SQL
        INSERT INTO packages
        (name, category_id, source_id)
        VALUES (?, ?, ?);
    SQL
})

