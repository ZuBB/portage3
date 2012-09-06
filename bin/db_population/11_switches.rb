#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

SWITCHES = ['none', 'or', 'if']

script = Script.new({
    'data_source' => Proc.new { SWITCHES },
    'sql_query' => 'INSERT INTO switch_types (type) VALUES (?);'
})

