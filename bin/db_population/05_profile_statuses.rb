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
    path = File.join(params['profiles2_home'], 'profiles.desc')
    results = %x[grep -oP '\t[a-z]*$' #{path}].split("\n") rescue []
    # drop first item since its a header
    results.shift
    # drop duplicates and strip leading \t
    results.uniq.map { |status| status.strip }
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO profile_statuses (status) VALUES (?);'
})

