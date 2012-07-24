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
		# TODO checks
		# 1. we should not have description_id with '0'
		# 2. every description should referenced at least once
		# 3. if checks are OK then we can delete tmp
        #sql_query = 'DROP TABLE IF EXISTS tmp_ebuild_descriptions;'
        #Database.select(sql_query)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'UPDATE ebuilds SET description_id=? WHERE id=?;'
})

