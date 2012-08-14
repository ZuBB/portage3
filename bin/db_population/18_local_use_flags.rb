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
    TYPE = 'local'

    def pre_insert_task
        @shared_data.merge!(UseFlag.pre_insert_task(TYPE))

        @shared_data['atom@id'] = {}
        sql_query = <<-SQL
            SELECT p.id, c.name, p.name
            FROM packages p
            JOIN categories c ON p.category_id = c.id;
        SQL
        Database.select(sql_query).each do |row|
            @shared_data['atom@id'][row[1] + '/' + row[2] + ':'] = row[0]
        end
    end

    def process(line)
        unless (matches = UseFlag::REGEXPS[TYPE].match(line)).nil?
            params = matches.to_a.drop(1)
            params << @shared_data['flag_type@id'][TYPE]
            params << @shared_data['source@id']['profiles']
            params << @shared_data['repo@id']['gentoo']
            params[0] = @shared_data['atom@id'][params[0]]
            Database.add_data4insert(*params)
        else
            PLogger.group_log([
                [3, 'Failed to parse next line'],
                [1, line]
            ])
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO flags
        (package_id, name, descr, type_id, source_id, repository_id)
        VALUES (?, ?, ?, ?, ?, ?);
    SQL
})

