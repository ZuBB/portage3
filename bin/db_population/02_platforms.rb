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
    # result here
    platforms = []
    # name of the file to be processed
    # TODO fix name of the 1st and 2nd params
    filename = File.join(params["profiles2_home"], "arch.list")

    # walk through all use lines in that file
    (IO.read(filename).to_a rescue []).each do |line|
        # skip comments
        next if line.index('#') == 0
        # skip empty lines and architectures
        next unless line.match(/\S+/) && line.include?('-')
        # remember
        platforms << line.split('-')[1].strip()
    end

    return platforms.uniq
end

def process(params)
    Database.add_data4insert(params["value"])
end

script = Script.new({
    "script" => __FILE__,
    "data_source" => method(:get_data),
    'sql_query' => 'INSERT INTO platforms (platform_name) VALUES (?);',
    "thread_code" => method(:process)
})

