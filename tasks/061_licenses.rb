#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'license'
require 'repository'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '021_repositories'
    self::SQL = {
        'insert' => <<-SQL
            INSERT OR IGNORE INTO licenses
            (name, repository_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        licenses = []
        Database.select(Repository::SQL['all']).each do |row|
            licenses_home = File.join(row[2], row[3], 'licenses')
            next unless File.exist?(licenses_home)
            licenses += Dir[File.join(licenses_home, '*')]
                .select { |item| File.size?(item) }
                .map { |item| item.slice(licenses_home.size + 1..-1) }
                .select { |item| License.is_license_valid?(item) }
                .map { |item| [item, row[0]] }
        end

        licenses
    end
end

Tasks.create_task(__FILE__, klass)

