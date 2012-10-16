#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    # NOTE we need to add those as they are used later
    results = ['x64', 'sparc64']
    filename = File.join(params['profiles_home'], 'arch.list')

    IO.foreach(filename) do |line|
        # break if we come down to prefixes
        break if line.include?('# Prefix keywords')
        next if line.start_with?('#')
        next if /^\s*$/ =~ line
        results << line.strip.split('-')[0]
    end

    results.uniq
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO architectures (name) VALUES (?);'
})

#amd64-fbsd
