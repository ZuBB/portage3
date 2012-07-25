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
    filename = File.join(params['profiles2_home'], 'use.desc')
    (IO.read(filename).split("\n") rescue []).select { |line|
        !line.start_with?('#') && /\S+/ =~ line
    }
end

class Script
    def pre_insert_task
        flag_type = 'global'
        flag_type_id = Database.get_1value(UseFlag::SQL['type'], flag_type)
        @shared_data['use_flag_types'] = {
            'global_flag_type_id' => flag_type_id
        }
    end

    def process(line)
        matches = UseFlag::Regexps['global'].match(line.strip)
        flag_type_id = @shared_data['use_flag_types']['global_flag_type_id']
        unless matches.nil?
            Database.add_data4insert(*matches.to_a.drop(1), flag_type_id)
        else
            PLogger.error("Failed to parse next line\n#{line}")
        end
    end

    def post_insert_task
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

