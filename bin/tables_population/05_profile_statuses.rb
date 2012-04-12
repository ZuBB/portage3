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

script = Script.new({
    "table" => "profile_statuses",
    "script" => __FILE__
})

def fill_table(params)
    path = File.join(params["portage_home"], "profiles", "profiles.desc")
    # lets find all lines from profiles.desc file
    results = %x[grep -oP '\t[a-z]*$' #{path}].to_a rescue []
    # drop first item since its a header
    results.shift()

    results.uniq.compact.each { |status|
        Database.insert({
            "table" => params["table"],
            "data" => {"profile_status" => status.strip!()}
        })
    }
end

script.fill_table_X(method(:fill_table))

