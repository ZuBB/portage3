#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/25/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '107_ebuild_homepages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds_homepages
            (homepage_id, ebuild_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        sql_query = <<-SQL
            SELECT eh.id, teh.ebuild_id
            FROM ebuild_homepages eh
            JOIN tmp_ebuild_homepages teh ON eh.homepage = teh.homepage;
        SQL
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)
