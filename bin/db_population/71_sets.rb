#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    ['installed']
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO sets (name) VALUES (?);'
})

