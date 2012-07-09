#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
$:.push File.expand_path(File.join(*(lib_path_items + ['portage'])))
require 'script'
require 'repository'

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
    "table" => "repositories",
    "script" => __FILE__,
    "thread_code" => method(:process),
    'sql_query' => 'INSERT INTO repositories (repository_name, parent_folder, repository_folder) VALUES (?, ?, ?);',
    "data_source" => Repository.method(:get_repositories)
})

