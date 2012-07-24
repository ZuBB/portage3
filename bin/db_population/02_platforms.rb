#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []
    filename = File.join(params['profiles2_home'], 'arch.list')

    IO.foreach(filename) do |line|
        next if line.start_with?('#')
        next if /^\s*$/ =~ line
        next unless line.include?('-')
        results << line.split('-')[1].strip()
    end

    results.uniq
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO platforms (platform_name) VALUES (?);'
})

