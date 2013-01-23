#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/25/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Script
    def post_insert_check
        sql_query = 'SELECT COUNT(id) FROM ebuilds_homepages WHERE homepage_id=0;'
        if (tmp = Database.get_1value(sql_query).to_i) > 0
            PLogger.error("Some ebuilds(#{tmp} items) miss its homepage")
            return
        end

        sql_query = <<-SQL
            SELECT COUNT(id)
            FROM ebuild_homepages
            WHERE id NOT IN (SELECT DISTINCT homepage_id from ebuilds_homepages);
        SQL
        if (tmp = Database.get_1value(sql_query).to_i) > 0
            PLogger.error("Some homepages(#{tmp} items) are not being used")
            return
        end
    end
end

