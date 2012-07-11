#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
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
    'script' => __FILE__,
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO mask_states (mask_state) VALUES (?);',
    'thread_code' => method(:process)
})

