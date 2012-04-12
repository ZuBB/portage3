#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "table" => "keywords",
    "script" => __FILE__
})

# TODO symbols
KEYWORDS = ['not work', 'not known', 'unstable', 'stable']

def fill_table(params)
    KEYWORDS.each { |keyword|
        Database.insert({
            "table" => params["table"],
            "data" => {"keyword" => keyword}
        })
    }
end

script.fill_table_X(method(:fill_table))

