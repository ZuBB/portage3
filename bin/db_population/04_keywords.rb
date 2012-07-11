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
    Database.add_data4insert(params["value"])
end

script = Script.new({
    "script" => __FILE__,
    "data_source" => method(:get_data),
    'sql_query' => 'INSERT INTO keywords (keyword) VALUES (?);',
    "thread_code" => method(:process)
})

