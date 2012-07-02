#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
$:.push File.expand_path(File.join(*(lib_path_items + ['portage'])))
require 'script'

def get_data(params)
    # query
    results = []

    filename = "/var/lib/portage/world"
    return results unless File.exist?(filename)

    # walk through all use lines in that file
    IO.foreach(filename) do |line|
        # lets trim newlines and insert
        line.chomp!()
        category_name = line.split('/')[0]
        package_name = line.split('/')[1]
        results << [category_name, package_name]
    end

    return results
end

def process(params)
    Database.insert({
        "values" => [params['value'][0], params['value'][1]],
        "sql_query" => <<-SQL
            INSERT INTO installed_apps
            (package_id)
            VALUES ((
                SELECT p.id
                FROM packages p
                JOIN categories c ON p.category_id=c.id
                WHERE c.category_name=? and p.package_name=?
            ))
        SQL
    })
end

script = Script.new({
    "script" => __FILE__,
    'thread_code' => method(:process),
    'data_source' => method(:get_data),
})

