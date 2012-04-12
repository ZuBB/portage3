#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "script" => __FILE__,
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

def fill_table(params)
    filename = File.join(params["portage_home"], "profiles_v2", "profiles.desc")

    # walk through all use flags in that file
    (IO.read(filename).to_a rescue []).each do |line|
        # skip header
        break if line.include?("Gentoo Prefix profiles")
        # skip comments
        next if line.index('# uclibc') == 0
        next if line.index('#') == 0 && !line.include?('uclibc')
        # lets trim newlines
        line.chomp!()
        # skip empty lines
        next if line.empty?

        # lets split flag and its description
        profile_stuff = line.sub("#", '').split()

        Database.insert({
            "sql_query" => params["sql_query"],
            "values" => [
                profile_stuff[1],
                profile_stuff[0],
                profile_stuff[2]
            ]
        })
    end
end

script.fill_table_X(method(:fill_table))

