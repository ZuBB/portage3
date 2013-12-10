#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::PRI_INDEX = 1.1
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO repositories
            (name, parent_folder, repository_folder)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        Repository.get_repositories(params)
    end

    def process_item(params)
        @logger.debug("Repository: #{params}")
        repository = Repository.new(params)

        send_data4insert({ 'data' => [
            repository.repository,
            repository.repository_pd,
            repository.repository_fs
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

