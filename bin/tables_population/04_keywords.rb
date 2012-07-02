#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
require 'script'

# TODO symbols
KEYWORDS = ['not work', 'not known', 'unstable', 'stable']

def get_data(params)
	return KEYWORDS
end

def process(params)
	Database.insert({
		"table" => params["table"],
		"data" => {"keyword" => params["value"]}
	})
end

script = Script.new({
    "script" => __FILE__,
    "table" => "keywords",
    "data_source" => method(:get_data),
    "thread_code" => method(:process)
})

