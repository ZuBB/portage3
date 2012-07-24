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
    filename = File.join(params['profiles2_home'], 'profiles.desc')

    IO.foreach(filename) do |line|
        break if line.include?('Gentoo Prefix profiles')
        # skip comments
        next if line.start_with?('# uclibc')
        # but do not skip uclibc stuff
        next if line.start_with?('#') && !line.include?('uclibc')
        next if /^\s*$/ =~ line

        results << [*line.sub('#', '').strip.split]
    end

    results
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO profiles
        (arch_id, profile_name, profile_status_id)
        VALUES (
            (SELECT id FROM arches WHERE arch_name=?),
            ?,
            (SELECT id FROM profile_statuses WHERE profile_status=?)
        );
    SQL
})

