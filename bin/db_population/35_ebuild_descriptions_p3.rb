#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    sql_query = 'SELECT description FROM ebuild_descriptions'
    Database.select(sql_query).flatten
end

class Script
    def process(desc)
        sql_query = <<-SQL
            SELECT ed.id, td.ebuild_id
            FROM ebuild_descriptions ed
            JOIN tmp_ebuild_descriptions td
                ON ed.description = td.description
            WHERE ed.description=?
        SQL

        Database.select(sql_query, desc).each do |row|
            Database.add_data4insert(row[0], row[1])
        end
    end

    def post_insert_task
        sql_query = 'SELECT COUNT(id) FROM ebuilds WHERE description_id=0'
        tmp = Database.get_1value(sql_query).to_i
        if tmp > 0
            PLogger.error("Some ebuilds(#{tmp} items) miss its description")
            return
        end

        sql_query = <<-SQL
            SELECT COUNT(id)
            FROM ebuild_descriptions
            WHERE id NOT IN (SELECT DISTINCT description_id from ebuilds)
        SQL
        tmp = Database.get_1value(sql_query).to_i
        if tmp > 0
            PLogger.error('Some descriptions(#{tmp} items) are is not being used')
            return
        end

        #sql_query = 'DROP TABLE IF EXISTS tmp_ebuild_descriptions;'
        #Database.select(sql_query)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'UPDATE ebuilds SET description_id=? WHERE id=?;'
})

