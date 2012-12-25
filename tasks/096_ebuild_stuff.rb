#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/02/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '093_read_ebuilds_data'
    self::SQL = {
        'insert' => <<-SQL
            UPDATE ebuilds
            SET
                mauthor = ?,
                mtime = ?,
                slot = ?
                WHERE id=?;
        SQL
    }

    def get_data(params)
        sql_query = 'SELECT mauthor, mtime, slot, ebuild_id FROM tmp_ebuilds_data;'
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)
