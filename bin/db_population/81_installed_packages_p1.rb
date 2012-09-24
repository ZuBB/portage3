#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'installed_package'

def get_data(params)
    Dir[File.join(InstalledPackage::DB_PATH, '**/*/')]
        .map { |item| item.sub(InstalledPackage::DB_PATH + '/', '') }
        .map { |item| item.sub(/\/$/, '') }
        .select { |item| item.count('/') == 1 }
end

class Script
    def pre_insert_task
        sql_query = <<-SQL
            DROP TABLE IF EXISTS tmp_installed_packages_repos;

            CREATE TABLE IF NOT EXISTS tmp_installed_packages_repos (
                name VARCHAR UNIQUE NOT NULL
            );
        SQL
        Database.execute(sql_query)
    end

    def process(item)
        item_path = File.join(InstalledPackage::DB_PATH, item)
        repo_file = File.join(item_path, 'repository')

        return unless File.size?(repo_file)

        Database.add_data4insert(IO.read(repo_file).strip)
    end

    def post_insert_task
        count_query = 'select count(id) from repositories;'
        # http://bit.ly/tLQydk
        sql_query = <<-SQL
            INSERT INTO repositories
            (name, parent_folder, repository_folder)
            SELECT tr.name, '/dev/null', tr.name
            FROM tmp_installed_packages_repos tr
            WHERE NOT EXISTS (
                SELECT name FROM repositories r WHERE r.name = tr.name
            );
        SQL

        tb = Database.get_1value(count_query)
        Database.execute(sql_query)
        ta = Database.get_1value(count_query)

        "#{ta - tb} successful inserts has beed done"
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT OR IGNORE INTO tmp_installed_packages_repos (name) VALUES (?);
    SQL
})

