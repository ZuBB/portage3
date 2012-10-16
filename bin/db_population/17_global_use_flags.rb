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
    filename = File.join(params['profiles_home'], 'use.desc')
    (IO.read(filename).split("\n") rescue []).select { |line|
        !line.start_with?('#') && /\S+/ =~ line
    }
end

class Script
    TYPE = 'global'

    def pre_insert_task
        @shared_data.merge!(UseFlag.pre_insert_task(TYPE))
    end

    def process(line)
        unless (matches = UseFlag::REGEXPS[TYPE].match(line)).nil?
            params = *matches.to_a.drop(1)
            params << @shared_data['flag_type@id'][TYPE]
            params << @shared_data['source@id']['profiles']
            params << @shared_data['repo@id']['gentoo']
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
        (name, descr, type_id, source_id, repository_id)
        VALUES (?, ?, ?, ?, ?);
    SQL
})

