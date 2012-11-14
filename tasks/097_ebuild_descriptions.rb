#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/02/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '096_ebuild_descriptions'
    self::SQL = {
        'insert' => 'UPDATE ebuilds SET description_id=? WHERE id=?;'
    }

    def get_data(params)
        sql_query = <<-SQL
            SELECT ed.id, td.ebuild_id
            FROM ebuild_descriptions ed
            JOIN tmp_ebuild_descriptions td ON ed.descr = td.descr;
        SQL
        Database.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)

