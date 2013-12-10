#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '091_ebuilds;155_profile_ebuilds'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds
            (version, package_id, repository_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = Ebuild::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_profile_ebuilds')
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)

