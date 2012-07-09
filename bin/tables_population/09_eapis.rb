#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
require 'script'

def get_data(params)
    # result here
    results = []
    # lets find all lines from all ebuilds that have EAPI string at 0 position
    search_pattern = "#{params['gentoo_tree_home']}/*/*/*ebuild"
    grep_command = "grep -h '^EAPI' #{search_pattern} 2> /dev/null"

    for letter in 'a'..'z':
        results += %x[#{grep_command.sub(/\*/, "#{letter}*")}].split("\n")
    end

    results.uniq.map { |line|
        line.sub(/#.*$/, '').gsub(/["' EAPI=]/, '')
    }.uniq
end

def process(params)
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'table' => 'eapis',
    'script' => __FILE__,
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO eapis (eapi_version) VALUES (?);',
    'thread_code' => method(:process)
})

