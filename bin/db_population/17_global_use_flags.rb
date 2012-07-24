#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'

def get_data(params)
    results = []
    # pattern for flag, its description
    pattern = Regexp.new('([\\w\\+\\-]+)(?: - )(.*)')
    flag_type_id = Database.get_1value(UseFlag::SQL['type'], 'global')

    IO.foreach(File.join(params['profiles2_home'], 'use.desc')) do |line|
        line.chomp!
        next if line.start_with?('#')
        next if line.empty?
        results << [*pattern.match(line).to_a.drop(1), flag_type_id]
    end

    results
end

class Script
    def post_insert_task()
        sql_query = <<-SQL
            SELECT COUNT(id)
            FROM use_flags
            WHERE flag_type_id=(#{UseFlag::SQL['type']})
        SQL

        total_global_flags = Database.get_1value(sql_query, 'global')

        sql_query = <<-SQL
            SELECT COUNT(DISTINCT flag_name)
            FROM use_flags
            WHERE flag_type_id=(#{UseFlag::SQL['type']})
        SQL
        unique_global_flags = Database.get_1value(sql_query, 'global')

        if total_global_flags != unique_global_flags
            PLogger.error('Its very likely that global flags have duplicates')
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO use_flags
        (flag_name, flag_description, flag_type_id)
        VALUES (?, ?, ?);
    SQL
})

