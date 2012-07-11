#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'repository'
require 'script'

def process(params)
    PLogger.info("Repository: #{params["value"]}")
    repository = Repository.new(params)

    Database.add_data4insert([
        repository.repository(),
        repository.repository_pd(),
        repository.repository_fs()
    ])
end

script = Script.new({
    'thread_code' => method(:process),
    'data_source' => Repository.method(:get_repositories),
    'sql_query' => 'INSERT INTO repositories (repository_name, parent_folder, repository_folder) VALUES (?, ?, ?);'
})

