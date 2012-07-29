#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Script
    def post_insert_check
        sql_query = <<-SQL
            SELECT COUNT(id)
            FROM flags
            WHERE type_id=(#{UseFlag::SQL['type']})
        SQL

        total_global_flags = Database.get_1value(sql_query, 'global')

        sql_query = <<-SQL
            SELECT COUNT(DISTINCT name)
            FROM flags
            WHERE type_id=(#{UseFlag::SQL['type']})
        SQL
        unique_global_flags = Database.get_1value(sql_query, 'global')

        if total_global_flags != unique_global_flags
            PLogger.error('Its very likely that global flags have duplicates')
        end
    end
end

