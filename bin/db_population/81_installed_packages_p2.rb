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
            DROP TABLE IF EXISTS tmp_installed_packages_cat;

            CREATE TABLE IF NOT EXISTS tmp_installed_packages_cat (
                name VARCHAR UNIQUE NOT NULL
            );
        SQL
        Database.execute(sql_query)
    end

    def process(item)
        Database.add_data4insert(item.split('/')[0])
    end

    def post_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, InstalledPackage::DB_PATH)

        count_query = 'select count(id) from categories;'
        # http://bit.ly/tLQydk
        sql_query = <<-SQL
            INSERT INTO categories
            (name, source_id)
            SELECT tc.name, #{source_id}
            FROM tmp_installed_packages_cat tc
            WHERE NOT EXISTS (
                SELECT name FROM categories c WHERE c.name = tc.name
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
        INSERT OR IGNORE INTO tmp_installed_packages_cat (name) VALUES (?);
    SQL
})

