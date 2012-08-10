#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    Database.select('SELECT descr FROM ebuild_descriptions').flatten
end

class Script
    def process(desc)
        sql_query = <<-SQL
            SELECT ed.id, td.ebuild_id
            FROM ebuild_descriptions ed
            JOIN tmp_ebuild_descriptions td ON ed.descr = td.description
            WHERE ed.descr=?
        SQL

        Database.select(sql_query, desc).each do |row|
            Database.add_data4insert(row[0], row[1])
        end
    end

    def post_insert_task
        Database.execute('DROP TABLE IF EXISTS tmp_ebuild_descriptions;')
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'UPDATE ebuilds SET description_id=? WHERE id=?;'
})

