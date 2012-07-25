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
                ON eh.description = teh.homepage
            WHERE eh.description=?
        SQL

        Database.select(sql_query, desc).each do |row|
            Database.add_data4insert(row[0], row[1])
        end
    end

    def post_insert_task
        sql_query = 'SELECT COUNT(id) FROM ebuilds_homepages WHERE homepage_id=0'
        if (tmp = Database.get_1value(sql_query).to_i) > 0
            PLogger.error("Some ebuilds(#{tmp} items) miss its homepage")
            return
        end

        sql_query = <<-SQL
            SELECT COUNT(id)
            FROM ebuild_descriptions
            WHERE id NOT IN (SELECT DISTINCT homepage_id from ebuilds_homepages)
        SQL
        if (tmp = Database.get_1value(sql_query).to_i) > 0
            PLogger.error("Some homepages(#{tmp} items) are not being used")
            return
        end

        # uncomment this after ..     :(
        #sql_query = 'DROP TABLE IF EXISTS tmp_ebuild_homepages;'
        #Database.execute(sql_query)
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO ebuilds_homepages
        (homepage_id, ebuild_id)
        VALUES (?, ?);
    SQL
})

