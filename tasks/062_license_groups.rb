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
    self::DEPENDS = '021_repositories'
    self::SQL = {
        'insert' => <<-SQL
            INSERT OR IGNORE INTO license_groups
            (name, repository_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        groups = []
        Database.select(Repository::SQL['all']).each do |row|
            groups_file = File.join(row[2], row[3], 'profiles', 'license_groups')
            next unless File.size?(groups_file)
            groups += IO.read(groups_file).split("\n")
                .reject { |line| /^\s*$/ =~ line }
                .reject { |line| /^\s*#/ =~ line }
                .map { |line| line.split[0] }
                .select { |item| License.is_group_valid?(item) }
                .map { |item| [item, row[0]] }
        end

        groups
    end
end

Tasks.create_task(__FILE__, klass)

