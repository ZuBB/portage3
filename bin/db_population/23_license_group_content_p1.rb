#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []
    filename = File.join(params['profiles2_home'], 'license_groups')

    # walk through all use flags in that file
    IO.foreach(filename) do |line|
        next if line.start_with?('#')
        next if /^\s*$/ =~ line

        # TODO group names may contain (its only assumption)
        #   [a-zA-Z0-9],
        #   _ (underscore),
        #   - (dash),
        #   . (dot)
        #   + (plus sign).
        # lets split flag and its description
        items = line.split()
        group = items.delete_at(0)

        items.each do |item|
            results << [group, item[1..-1]] if item.start_with?('@')
        end
    end

    results
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO licence_group_content
        (group_id, sub_group_id)
        VALUES (
            (SELECT id FROM licence_groups WHERE name=?),
            (SELECT id FROM licence_groups WHERE name=?)
        );
    SQL
})

