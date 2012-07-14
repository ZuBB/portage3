#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'

def get_data(params)
    # result here
    platforms = []
    # name of the file to be processed
    # TODO fix name of the 1st and 2nd params
    filename = File.join(params['profiles2_home'], 'arch.list')

    # walk through all use lines in that file
    IO.foreach(filename) do |line|
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
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO platforms (platform_name) VALUES (?);'
})

