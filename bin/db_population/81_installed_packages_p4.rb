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
            DROP TABLE IF EXISTS tmp_installed_packages_ebld;

            CREATE TABLE IF NOT EXISTS tmp_installed_packages_ebld (
                package_id INTEGER NOT NULL,
                version VARCHAR NOT NULL,
                repository VARCHAR NOT NULL,
                source_id INTEGER NOT NULL
            );
        SQL
        Database.execute(sql_query)

        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, InstalledPackage::DB_PATH)
        @shared_data['source@id'] = { InstalledPackage::DB_PATH => source_id }

        sql_query = 'select name, id from repositories;'
        @shared_data['repo@id'] = Hash.new[Database.get_1value(sql_query)]

        @shared_data['package@id'] = {}
        sql_query = <<-SQL
            SELECT p.id, c.name, p.name
            FROM packages p
            JOIN categories c ON p.category_id = c.id;
        SQL

        Database.select(sql_query).each do |row|
            @shared_data['package@id']["#{row[1]}/#{row[2]}"] = row[0]
        end
    end

    def process(item)
        item_path  = File.join(InstalledPackage::DB_PATH, item)
        repo       = IO.read(File.join(item_path, 'repository')).strip

        category, pf = item.split('/')
        if /-r\d+$/ =~ pf
            # has -rX
            verstion_start = /-[^-]+-r\d+$/ =~ pf
        else
            # does not have -rX
            verstion_start = /-[^-]+$/ =~ pf
        end
        package = pf[0...verstion_start]
        version = pf[verstion_start + 1..-1]

        Database.add_data4insert(
            @shared_data['package@id']["#{category}/#{package}"],
            version,
            repo,
            @shared_data['source@id'][InstalledPackage::DB_PATH]
        )
    end

    def post_insert_task
        count_query = 'select count(id) from ebuilds;'
        # http://bit.ly/tLQydk
        sql_query = <<-SQL
            INSERT INTO ebuilds
            (package_id, version, source_id, repository_id)
            SELECT
                te.package_id,
                te.version,
                te.source_id,
                r.id
            FROM tmp_installed_packages_ebld te
            JOIN repositories r ON r.name=te.repository
            WHERE NOT EXISTS (
                SELECT id
                FROM ebuilds e
                WHERE
                    e.version = te.version AND
                    e.package_id = te.package_id
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
        INSERT OR IGNORE INTO tmp_installed_packages_ebld
        (package_id, version, repository, source_id)
        VALUES (?, ?, ?, ?);
    SQL
})

