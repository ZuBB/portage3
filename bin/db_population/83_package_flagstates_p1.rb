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
require 'useflag'

class Script
    def pre_insert_task
        sql_query = <<-SQL
            CREATE TABLE IF NOT EXISTS tmp_dropped_flags (
                name VARCHAR
            );
        SQL
        Database.execute(sql_query)

        sql_query = 'select name from flags;'
        @shared_data['flags'] = Database.select(sql_query).flatten
    end

    def process(param)
        iebuild_id = param[0]

        return unless (file = InstalledPackage.get_file(param, 'USE'))

        IO.read(file).split.each do |flag|
            flag_name = UseFlag.get_flag(flag)
            next if @shared_data['flags'].include?(flag_name)
            Database.add_data4insert(flag_name)
        end
    end

    def post_insert_task
        count_query = 'select count(id) from flags;'
        sql_query = <<-SQL
            INSERT INTO flags
            (name, type_id, live)
            SELECT
                distinct name,
                #{Database.get_1value(UseFlag::SQL['type'], 'unknown')},
                0
            FROM tmp_dropped_flags;
        SQL

        tb = Database.get_1value(sql_query)
        Database.execute(sql_query)
        ta  = Database.get_1value(sql_query)

        PLogger.info("#{ta - tb} successful insert has beed done")
    end
end

script = Script.new({
    'data_source' => InstalledPackage.method(:get_data),
    'sql_query' => 'INSERT INTO tmp_dropped_flags (name) VALUES (?);'
})

