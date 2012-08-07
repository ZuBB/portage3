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
    Database.select('SELECT distinct name FROM tmp_dropped_flgas').flatten
end

class Script
    def pre_insert_task
        type = 'unknown'
        type_id = Database.get_1value(UseFlag::SQL['type'], type)
        @shared_data['flag_type@id'] = { type => type_id }
    end

    def process(flag)
		type_id = @shared_data['flag_type@id']['unknown']
		Database.add_data4insert(flag, type_id, 0)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO flags (name, type_id, live) VALUES (?, ?, ?);'
})

