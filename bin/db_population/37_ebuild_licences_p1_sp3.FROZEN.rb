#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'ebuild'

def get_data(params)
    sql_query = <<-SQL
        select ls.id, license
        from license_specs ls
        join tmp_ebuild_licenses_p1 tmp1 on tmp1.id = ls.id;
    SQL
    Database.select(sql_query)
end

class Script
    def pre_insert_task
        sql_query = 'select name, id from licenses;'
        @shared_data['license@id'] = Hash[Database.select(sql_query)]
    end

    def process(params)
        params[1] = @shared_data['license@id'][params[1]]
        Database.add_data4insert(params)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO license_spec_content
        (license_spec_id, license_id)
        VALUES (?, ?);
    SQL
})

