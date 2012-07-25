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
    sql_query = 'SELECT distinct homepage FROM tmp_ebuild_homepages'
    Database.select(sql_query).flatten
end

class Script
    def pre_insert_task()
        Database.execute('DELETE FROM ebuild_homepages;')
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO ebuild_homepages (homepage) VALUES (?);'
})

