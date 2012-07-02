#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
require 'script'

def get_data(params)
    # path to be processed
    path = File.join(params["profiles2_home"], "profiles.desc")
    # lets find all lines from profiles.desc file
    results = %x[grep -oP '\t[a-z]*$' #{path}].to_a rescue []
    # drop first item since its a header
    results.shift()
    # drop items that repeat and are empty and return
    return results.uniq.compact.map { |status| status.strip }
end

def process(params)
	Database.insert({
		"table" => params["table"],
		"data" => {"profile_status" => params["value"]}
	})
end

script = Script.new({
    "script" => __FILE__,
    "table" => "profile_statuses",
    "data_source" => method(:get_data),
    "thread_code" => method(:process)
})

