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
        select ebuild_id, ls.id
        from tmp_ebuild_licenses_p1 tmp1 
        join license_specs ls on ls.id = tmp1.id;
    SQL
    Database.select(sql_query)
end

class Script
    def post_insert_task
        Database.execute('DROP TABLE IF EXISTS tmp_ebuild_licenses_p1;')
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO ebuilds_license_specs
        (ebuild_id, license_spec_id)
        VALUES (?, ?);
    SQL
})

