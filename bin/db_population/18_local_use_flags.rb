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
    filename = File.join(params['profiles2_home'], 'use.local.desc')
    (IO.read(filename).split("\n") rescue []).select { |line|
        !line.start_with?('#') && /\S+/ =~ line
    }
end

class Script
    def pre_insert_task()
        @shared_data['atom@id'] = {}
        sql_query = <<-SQL
            SELECT p.id, c.category_name, p.package_name
            FROM packages p
            JOIN categories c ON p.category_id = c.id;
        SQL
        Database.select(sql_query).each do |row|
            @shared_data['atom@id'][row[1] + '/' + row[2] + ':'] = row[0]
        end

        type = 'local'
        type_id = Database.get_1value(UseFlag::SQL['type'], type)
        @shared_data['flag_type@id'] = { type => type_id }
    end

    def process(line)
        unless (matches = UseFlag::Regexps['local'].match(line)).nil?
            matches = matches.to_a.drop(1)
            matches[0] = @shared_data['atom@id'][matches[0]]
            type_id = @shared_data['flag_type@id']['local']
            Database.add_data4insert(*matches, type_id)
        else
            PLogger.error("Failed to parse next line\n#{line}")
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO flags
        (package_id, name, descr, type_id)
        VALUES (?, ?, ?, ?);
    SQL
})

