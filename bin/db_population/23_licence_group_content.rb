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

        line = []
        items.each do |item|
            licence = nil
            sub_group = nil

            if item.start_with?('@')
                sub_group = item[1..-1]
            else
                licence = item
            end

            results << [group, sub_group, licence]
        end
    end

    results
end

class Script
    def get_shared_data()
        sql_query = 'SELECT name, id FROM licence_groups;'
        @shared_data['licence_groups@id'] = Hash[Database.select(sql_query)]

        sql_query = 'SELECT name, id FROM licences;'
        @shared_data['licences@id'] = Hash[Database.select(sql_query)]
    end

    def process(params)
        Database.add_data4insert(@shared_data['licence_groups@id'][params[0]],
                                 @shared_data['licence_groups@id'][params[1]],
                                 @shared_data['licences@id'][params[2]]
                                )
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO licence_group_content
        (group_id, sub_group_id, licence_id)
        VALUES (?, ?, ?);
    SQL
})

