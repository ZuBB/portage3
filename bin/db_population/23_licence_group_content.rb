#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'

def get_data(params)
    # name of the file to be processed
    filename = File.join(params['profiles2_home'], 'license_groups')

    # walk through all use flags in that file
    (IO.read(filename).to_a rescue []).map do |line|
        # skip comments
        next if line.start_with?('#')
        # skip empty lines
        next unless line.match(/\S+/)

        # TODO group names may contain (its only assumption)
        #   [a-zA-Z0-9],
        #   _ (underscore),
        #   - (dash),
        #   . (dot)
        #   + (plus sign).
        # lets split flag and its description
        line
    end
end

def process(params)
    items = params['value'].split()
    group = items.delete_at(0)

    items.each do |item|
        licence = nil
        sub_group = nil

        if item.start_with?('@')
            sub_group = item[1..-1]
        else
            licence = item
        end

        Database.add_data4insert([group, sub_group, licence])
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => <<-SQL
        INSERT INTO licence_group_content
        (group_id, sub_group_id, licence_id)
        VALUES (
            (SELECT id FROM licence_groups WHERE name=?),
            (SELECT id FROM licence_groups WHERE name=?),
            (SELECT id FROM licences WHERE name=?)
        );
    SQL
})

