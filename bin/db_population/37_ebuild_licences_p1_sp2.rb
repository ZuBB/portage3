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
    sql_query = 'select id from license_spec_types where spec_type = ?;'
    spec_type_id = Database.get_1value(sql_query, Script::SPEC_TYPE)

    sql_query = 'select count(id) from tmp_ebuild_licenses_p1;'
    array_size = Database.get_1value(sql_query)
    Array.new(array_size, spec_type_id)
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO license_specs (spec_type_id) VALUES (?);'
})

