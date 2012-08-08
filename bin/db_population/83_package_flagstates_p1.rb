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
            CREATE TABLE IF NOT EXISTS tmp_dropped_flgas (
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
end

script = Script.new({
    'data_source' => InstalledPackage.method(:get_data),
    'sql_query' => 'INSERT INTO tmp_dropped_flgas (name) VALUES (?);'
})

