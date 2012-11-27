#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'repository'
require 'installed_package'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '021_repositories;601_installed_packages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO repositories
            (name, repository_folder, parent_folder)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = Repository::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_installed_packages_repos')
        Database.select(sql_query).flatten
    end

    def process_item(item)
        send_data4insert({'data' => (Array.new(2, item) << '/dev/null')})
    end
end

Tasks.create_task(__FILE__, klass)

