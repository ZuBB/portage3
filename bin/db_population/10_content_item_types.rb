#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

KEYWORDS = ['dir', 'obj', 'sym']

script = Script.new({
    'data_source' => Proc.new { KEYWORDS },
    'sql_query' => 'INSERT INTO content_item_types (type) VALUES (?);'
})

