#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
require 'script'

FLAG_STATES = ['masked', 'disabled', 'enabled', 'forced']

def get_data(params)
    FLAG_STATES
end

def process(params)
    Database.add_data4insert(params["value"])
end

script = Script.new({
    "table" => "use_flags_states",
    "script" => __FILE__,
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO use_flags_states (flag_state) VALUES (?);',
    'thread_code' => method(:process)
})

