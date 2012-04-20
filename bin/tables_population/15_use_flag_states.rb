#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

FLAG_STATES = ['masked', 'disabled', 'enabled', 'forced']

script = Script.new({
    "table" => "use_flags_states",
    "script" => __FILE__
})

def fill_table(params)
    # array of all keywords
    FLAG_STATES.each { |state|
        Database.insert({
            "table" => params["table"],
            "data" => {"flag_state" => state}
        })
    }
end

script.fill_table_X(method(:fill_table))

