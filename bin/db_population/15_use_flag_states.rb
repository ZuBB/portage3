#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

FLAG_STATES = ['masked', 'disabled', 'enabled', 'forced']

script = Script.new({
    'data_source' => Proc.new { FLAG_STATES },
    'sql_query' => 'INSERT INTO use_flag_states (flag_state) VALUES (?);'
})

