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
    profiles = []
    # name of the file to be processed
    filename = File.join(params["profiles2_home"], "profiles.desc")

    # walk through all use flags in that file
    (IO.read(filename).to_a rescue []).each do |line|
        # stop if we face with header of 'prefix profiles'
        break if line.include?("Gentoo Prefix profiles")
        # skip comments
        next if line.start_with?('# uclibc')
        next if line.start_with?('#') && !line.include?('uclibc')
        # skip empty lines
        next unless line.match(/\S+/)

        # lets split flag and its description
        profile_stuff = line.strip.sub("#", '').split()
        # remember all
        profiles << [profile_stuff[1], profile_stuff[0], profile_stuff[2]]
    end

    return profiles
end

def process(params)
    Database.add_data4insert(params["value"])
end

script = Script.new({
    "script" => __FILE__,
    "data_source" => method(:get_data),
    "thread_code" => method(:process),
    "sql_query" => <<SQL
INSERT INTO profiles
(profile_name, arch_id, profile_status_id)
VALUES (
    ?,
    (SELECT id FROM arches WHERE arch_name=?),
    (SELECT id FROM profile_statuses WHERE profile_status=?)
);
SQL
})

