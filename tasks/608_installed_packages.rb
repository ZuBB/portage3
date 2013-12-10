#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '412_users_mask;607_installed_packages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds
            (version, package_id, repository_id, /*slot,*/ source_id)
            VALUES (?, ?, ?, /*?,*/ ?);
        SQL
    }

    def get_data(params)
        sql_query = Ebuild::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_installed_packages_ebuilds')
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)
