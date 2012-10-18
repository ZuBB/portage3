#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'repository'

def get_data(params)
    items = []
    Database.select(Repository::SQL['all']).each do |row|
        groups_file = File.join(row[2], row[3], 'profiles', 'license_groups')
        next unless File.size?(groups_file)
        items += IO.read(groups_file).split("\n")
            .reject { |line| /^\s*$/ =~ line }
            .reject { |line| /^\s*#/ =~ line }
            .map { |line|
                licenses = line.split
                group = licenses.delete_at(0)
                licenses = licenses.reject { |item| item.start_with?('@') }
                licenses.map { |item| [group, item] }
            }
            .reject { |array| array.empty? }
    end

    items.flatten(1)
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO license_group_content
        (group_id, license_id)
        VALUES (
            (SELECT id FROM license_groups WHERE name=?),
            (SELECT id FROM licenses WHERE name=?)
        );
    SQL
})

