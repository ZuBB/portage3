#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []

    filename = '/var/lib/portage/world'
    return results unless File.exist?(filename)

    IO.foreach(filename) do |line|
        next if line.chomp!().empty?
        category_name = line.split('/')[0]
        package_name = line.split('/')[1]
        results << [category_name, package_name]
    end

    results
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO installed_apps
        (package_id)
        VALUES ((
            SELECT p.id
            FROM packages p
            JOIN categories c ON p.category_id=c.id
            WHERE c.name=? and p.name=?
        ));
    SQL
})

