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
    # name of the file to be processed
    filename = File.join(params['profiles2_home'], 'license_groups')

    # walk through all use flags in that file
    IO.read(filename).split("\n").map() do |line|
        line = nil if line.start_with?('#')
        line = nil if /^\s*$/ =~ line

        # TODO group names may contain
        #   [a-zA-Z0-9],
        #   _ (underscore),
        #   - (dash),
        #   . (dot)
        #   + (plus sign).
        # lets split flag and its description
        line.nil?() ? nil : line.split()[0]
    end .compact
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO licence_groups (name) VALUES (?);'
})

