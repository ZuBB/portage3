#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'

def get_data(params)
    sql_query = <<-SQL
        SELECT ip.id, c.category_name, p.package_name, e.version
        FROM installed_packages ip
        JOIN ebuilds e ON e.id = ip.ebuild_id
        JOIN packages p ON e.package_id = p.id
        JOIN categories c ON p.category_id = c.id;
    SQL

    Database.select(sql_query)
end

class Script
    def pre_insert_task
        sql_query = <<-SQL
            CREATE TABLE IF NOT EXISTS tmp_dropped_flgas (
                name VARCHAR
            );
        SQL
        Database.execute(sql_query)

        sql_query = 'select name from flags;'
        @shared_data['flags'] = Database.select(sql_query).flatten
    end

    def process(param)
        path = '/var/db/pkg'
        dir = File.join(path, param[1], param[2] + '-' + param[3])
        iebuild_id = param[0]

        # TODO what use files should be processed?
        # ['REQUIRED_USE', 'PKGUSE', 'IUSE', 'USE']
        ['USE'].each do |file|
            unless File.exist?(use_file = File.join(dir, file))
                PLogger.info("USE file does not exist for '#{dir}'")
                next
            end

            IO.read(use_file).split.each do |flag|
                flag_name = UseFlag.get_flag(flag)
                next if @shared_data['flags'].include?(flag_name)
                Database.add_data4insert(flag_name)
            end
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO tmp_dropped_flgas (name) VALUES (?);'
})

