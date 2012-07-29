#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Script
    def post_insert_task
        sql_query = <<-SQL
            SELECT ft.type, f.name
            FROM flags f
            JOIN flag_types ft ON ft.id=f.type_id
            WHERE f.descr='';
        SQL

        Database.get_1value(sql_query).each { |row|
            PLogger.error("#{row[0]} use flag #{row[1]} don't have description")
        }
    end
end

