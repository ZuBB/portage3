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
        unless (matches = UseFlag::REGEXPS['global'].match(line)).nil?
            type_id = @shared_data['flag_type@id']['global']
            Database.add_data4insert(*matches.to_a.drop(1), type_id)
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
    'sql_query' => 'INSERT INTO flags (name, descr, type_id) VALUES (?, ?, ?);'
})

