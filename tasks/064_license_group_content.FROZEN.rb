#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'license'
require 'repository'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '061_licenses;062_license_groups'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO license_group_content
            (group_id, license_id)
            VALUES (?, ?);
        SQL
    }

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

    def set_shared_data
        request_data('license_group@id', License::SQL['@1'])
        request_data('license@id', License::SQL['@2'])
    end

    def process_item(params)
        send_data4insert({
            'raw_data' => [params[0], params[1]],
            'data' => [
                shared_data('license_group@id', params[0]),
                shared_data('license@id', params[1])
            ]
        })
    end
end

Tasks.create_task(__FILE__, klass)

