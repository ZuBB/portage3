#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

# mask states
MASK_STATES = ['masked', 'unmasked']

script = Script.new({
    'data_source' => Proc.new { MASK_STATES },
    'sql_query' => 'INSERT INTO mask_states (state) VALUES (?);'
})

