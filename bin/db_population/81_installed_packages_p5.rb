#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
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
        @shared_data['atom@id'] = {}
        sql_query = <<-SQL
            SELECT e.id, c.name, p.name, e.version
            FROM ebuilds e
            JOIN packages p ON e.package_id = p.id
            JOIN categories c ON p.category_id = c.id;
        SQL

        Database.select(sql_query).each do |row|
            @shared_data['atom@id']["#{row[1]}/#{row[2]}-#{row[3]}"] = row[0]
        end

        sql_query = 'select name, id from repositories;'
        @shared_data['repo@id'] = Hash.new[Database.get_1value(sql_query)]
    end

    def process(item)
        params = [@shared_data['atom@id'][item]]
        item_path  = File.join(InstalledPackage::DB_PATH, item)

        params << IO.read(File.join(item_path, 'SIZE')).strip
        params << IO.read(File.join(item_path, 'SLOT')).strip
        params << IO.read(File.join(item_path, 'BUILD_TIME')).strip
        params << IO.read(File.join(item_path, 'BINPKGMD5')).strip rescue nil

        Database.add_data4insert(params)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO installed_packages
        (ebuild_id, pkgsize, slot, build_time, binpkgmd5)
        VALUES (?, ?, ?, ?, ?);
    SQL
})

