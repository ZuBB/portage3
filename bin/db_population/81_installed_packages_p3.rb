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
            DROP TABLE IF EXISTS tmp_installed_packages_pkg;

            CREATE TABLE IF NOT EXISTS tmp_installed_packages_pkg (
                cname VARCHAR NOT NULL,
                pname VARCHAR NOT NULL,
                CONSTRAINT idx1_unq UNIQUE (pname, cname)
            );
        SQL
        Database.execute(sql_query)
    end

    def process(item)
        category, pf = item.split('/')
        if /-r\d+$/ =~ pf
            # has -rX
            verstion_start = /-[^-]+-r\d+$/ =~ pf
        else
            # does not have -rX
            verstion_start = /-[^-]+$/ =~ pf
        end
        package = pf[0...verstion_start]
        Database.add_data4insert(category, package)
    end

    def post_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, InstalledPackage::DB_PATH)

        count_query = 'select count(id) from packages;'
        # http://bit.ly/tLQydk
        sql_query = <<-SQL
            INSERT INTO packages
            (name, category_id, source_id)
            SELECT tp.pname, c.id, #{source_id}
            FROM tmp_installed_packages_pkg tp
            JOIN categories c ON c.name=tp.cname
            WHERE NOT EXISTS (
                SELECT name FROM packages p WHERE p.name = tp.pname
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
        INSERT OR IGNORE INTO tmp_installed_packages_pkg (cname, pname) VALUES (?, ?);
    SQL
})

