#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []
    search_path = "#{params['tree_home']}/*/*/*ebuild"
    # lets find line from all ebuilds that have string with EAPI at 0 position
    grep_command = "grep -h '^EAPI' #{search_path} 2> /dev/null"

    for letter in 'a'..'z'
        results += %x[#{grep_command.sub(/\*/, "#{letter}*")}].split("\n")
    end

    results.uniq.map { |line|
        line.sub(/#.*$/, '').gsub(/["' EAPI=]/, '')
    }.uniq
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO eapis (version) VALUES (?);'
})

