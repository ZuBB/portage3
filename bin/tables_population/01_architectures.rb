#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "table" => "architectures",
    "script" => __FILE__
})

def fill_table(params)
    architectures = []
    # ********************* TODO *********************
    # ********************* TODO *********************
    # TODO what is better approach: add architectures here or in "arch.list" file?
    architectures << 'x64'
    architectures << 'sparc64'
    # ********************* TODO *********************
    # ********************* TODO *********************

    filename = File.join(params["portage_home"], "profiles", "arch.list")

    # walk through all use lines in that file
    (IO.read(filename).to_a rescue []).each do |line|
        # break if we face with prefixes
        break if line.include?("# Prefix keywords")
        # skip comments
        next if line.index('#') == 0
        # trim '\s'
        line.chomp!()
        # skip empty lines
        architectures << line unless line.empty?
    end

    architectures.each { |arch|
        Database.insert({
            "table" => params["table"],
            "data" => {"architecture" => arch}
        })
    }
end

script.fill_table_X(method(:fill_table))

