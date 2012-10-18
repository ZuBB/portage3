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
require 'parser'

def get_data(params)
    filename = File.join(params['profiles_home'], 'base', 'make.defaults')
    content = IO.read(filename).split("\n")
    Parser.get_multi_line_ini_value(content, 'USE_EXPAND_VALUES_ARCH').split
end

class Script
    TYPE = 'arch'

    def pre_insert_task
        @shared_data.merge!(UseFlag.pre_insert_task(TYPE))
    end

    def process(flag)
        params = [flag]
        params << @shared_data['flag_type@id'][TYPE]
        params << @shared_data['source@id']['profiles']
        params << @shared_data['repo@id']['gentoo']

        Database.add_data4insert(*params)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO flags
        (name, type_id, source_id, repository_id)
        VALUES (?, ?, ?, ?);
    SQL
})

