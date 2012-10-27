#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'

script = Script.new({
    'data_source' => Proc.new { UseFlag::STATES },
    'sql_query' => 'INSERT INTO flag_states (state, status) VALUES (?, ?);'
})

