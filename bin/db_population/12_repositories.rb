#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'repository'

class Script
    def process(params)
        PLogger.debug("Repository: #{params}")
        repository = Repository.new(params)

        Database.add_data4insert(repository.repository,
                                 repository.repository_pd,
                                 repository.repository_fs
                                )
    end
end

script = Script.new({
    'data_source' => Repository.method(:get_repositories),
    'sql_query' => <<-SQL
        INSERT INTO repositories
        (repository_name, parent_folder, repository_folder)
        VALUES (?, ?, ?);
    SQL
})

