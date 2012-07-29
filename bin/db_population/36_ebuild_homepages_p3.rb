#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/25/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    Database.select('SELECT homepage FROM ebuild_homepages').flatten
end

class Script
    def pre_insert_task()
        Database.execute('DELETE from ebuilds_homepages;')
    end

    def process(homepage)
        sql_query = <<-SQL
            SELECT eh.id, teh.ebuild_id
            FROM ebuild_homepages eh
            JOIN tmp_ebuild_homepages teh
                ON eh.homepage = teh.homepage
            WHERE eh.homepage=?
        SQL

        Database.select(sql_query, homepage).each do |row|
            Database.add_data4insert(row[0], row[1])
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO ebuilds_homepages
        (homepage_id, ebuild_id)
        VALUES (?, ?);
    SQL
})

