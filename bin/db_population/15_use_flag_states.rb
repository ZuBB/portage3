#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'

FLAG_STATES = ['masked', 'disabled', 'enabled', 'forced']

def get_data(params)
    FLAG_STATES
end

def process(params)
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO use_flags_states (flag_state) VALUES (?);'
})

