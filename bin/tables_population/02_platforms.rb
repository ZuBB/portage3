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
    "table" => "platforms",
    "script" => __FILE__
})

def fill_table(params)
    filename = File.join(params["portage_home"], "profiles", "arch.list")
    platforms = []

    # walk through all use lines in that file
    (IO.read(filename).to_a rescue []).each do |line|
        # skip comments
        next if line.index('#') == 0
        # trim '\n'
        line.chomp!()
        # skip empty lines
        next if line.empty?()
        # skip architectures
        next unless line.include?('-')

        # remember
        platforms << line.split('-')[1]
    end

    platforms.uniq.each { |platform|
        # lets trim newlines and insert
        Database.insert({
            "table" => params["table"],
            "data" => {"platform_name" => platform.chomp()}
        })
    }
end

script.fill_table_X(method(:fill_table))

