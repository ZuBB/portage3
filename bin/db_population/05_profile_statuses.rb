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
    # path to be processed
    path = File.join(params['profiles2_home'], 'profiles.desc')
    # lets find all lines from profiles.desc file
    results = %x[grep -oP '\t[a-z]*$' #{path}].to_a rescue []
    # drop first item since its a header
    results.shift()
    # drop items that repeat and are empty and return
    return results.uniq.compact.map { |status| status.strip }
end

def process(params)
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO profile_statuses (profile_status) VALUES (?);'
})

