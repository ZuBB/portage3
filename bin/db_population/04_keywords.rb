#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'keyword'

script = Script.new({
    'data_source' => Proc.new { Keyword::LABELS },
    'sql_query' => 'INSERT INTO keywords (name) VALUES (?);'
})

