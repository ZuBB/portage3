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
        type = 'global'
        type_id = Database.get_1value(UseFlag::SQL['type'], type)
        @shared_data['flag_type@id'] = { type => type_id }
    end

    def process(line)
        unless (matches = UseFlag::Regexps['global'].match(line)).nil?
            type_id = @shared_data['flag_type@id']['global']
            Database.add_data4insert(*matches.to_a.drop(1), type_id)
        else
            PLogger.error("Failed to parse next line\n#{line}")
        end
    end

    def post_insert_task
        sql_query = <<-SQL
            SELECT COUNT(id)
            FROM flags
            WHERE type_id=(#{UseFlag::SQL['type']})
        SQL

        total_global_flags = Database.get_1value(sql_query, 'global')

        sql_query = <<-SQL
            SELECT COUNT(DISTINCT name)
            FROM flags
            WHERE type_id=(#{UseFlag::SQL['type']})
        SQL
        unique_global_flags = Database.get_1value(sql_query, 'global')

        if total_global_flags != unique_global_flags
            PLogger.error('Its very likely that global flags have duplicates')
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO flags (name, descr, type_id) VALUES (?, ?, ?);'
})

