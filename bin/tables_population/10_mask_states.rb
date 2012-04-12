#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

# mask states
MASK_STATES = ['masked', 'unmasked']

script = Script.new({
    "table" => "mask_states",
    "script" => __FILE__
})

def fill_table(params)
    # insertions
    MASK_STATES.each { |keyword|
        Database.insert({
            "table" => params["table"],
            "data" => {"mask_state" => keyword}
        })
    }
end

script.fill_table_X(method(:fill_table))

