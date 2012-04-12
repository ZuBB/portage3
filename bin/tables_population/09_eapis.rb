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
    "table" => "eapis",
    "script" => __FILE__
})

def fill_table(params)
    results = []
    # lets find all lines from all ebuilds that have EAPI string 0 position
    grep_command = "grep -h '^EAPI' #{params["portage_home"]}/*/*/*ebuild 2> /dev/null"

    for letter in 'a'..'z':
        results += %x[#{grep_command.sub(/\*/, "#{letter}*")}].split("\n")
    end

    results.map! { |line|
        line.sub(/#.*$/, '').gsub(/['" EAPI=]/, '')
    }

    results.uniq.compact.each { |eapi|
        Database.insert({
            "table" => params["table"],
            "data" => {"eapi_version" => eapi}
        })
    }
end

script.fill_table_X(method(:fill_table))

