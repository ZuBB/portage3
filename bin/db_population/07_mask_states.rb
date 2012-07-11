#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'

# mask states
MASK_STATES = ['masked', 'unmasked']

def get_data(params)
    MASK_STATES
end

def process(params)
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO mask_states (mask_state) VALUES (?);'
})

