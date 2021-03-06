#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '021_repositories;601_installed_packages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO repositories
            (name, parent_folder, repository_folder)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = Repository::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_installed_packages_repos')
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)

