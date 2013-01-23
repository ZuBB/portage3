#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Script
    def post_insert_check
        sql_query = 'SELECT COUNT(id) FROM ebuilds WHERE description_id=0;'
        if (tmp = Database.get_1value(sql_query).to_i) > 0
            PLogger.error("Some ebuilds(#{tmp} items) miss its description")
            return
        end

        sql_query = <<-SQL
            SELECT COUNT(id)
            FROM ebuild_descriptions
            WHERE id NOT IN (SELECT DISTINCT description_id from ebuilds);
        SQL
        if (tmp = Database.get_1value(sql_query).to_i) > 0
            PLogger.error("Some descriptions(#{tmp} items) are not being used")
            return
        end
    end
end

