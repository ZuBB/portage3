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
    # name of the file to be processed
    filename = File.join(params['profiles2_home'], 'license_groups')

    # walk through all use flags in that file
    (IO.read(filename).to_a rescue []).map do |line|
        # skip comments
        next if line.start_with?('#')
        # skip empty lines
        next unless line.match(/\S+/)

        # TODO group names may contain
        #   [a-zA-Z0-9],
        #   _ (underscore),
        #   - (dash),
        #   . (dot)
        #   + (plus sign).
        # lets split flag and its description
        line.split()[0]
    end
end

def process(params)
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => <<-SQL
        INSERT INTO licence_groups
        (name)
        VALUES (?);
    SQL
})

