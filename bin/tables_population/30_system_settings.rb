#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/07/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
require 'script'
require 'parser'

def get_data(params)
    accept_keywords = Parser.get_multi_line_ini_value(
        (IO.read('/etc/make.conf').to_a rescue []),
        'ACCEPT_KEYWORDS'
    )

    if accept_keywords.include?('0_ACCEPT_KEYWORDS')
        puts 'Error Can not find `ACCEPT_KEYWORDS` variable in make.conf'
        exit(1)
    end

    keyword_name = accept_keywords.index('~') == 0 ? 'unstable' : 'stable'
    arch_name = accept_keywords.sub(/^~/, '')
    return [
        ["arch", Database.get_1value(
            "SELECT id FROM arches WHERE arch_name=?", arch_name
        ).to_s],
        ["keyword", Database.get_1value(
            "SELECT id FROM keywords WHERE keyword=?", keyword_name
        ).to_s]
    ]
end

def process(params)
    Database.add_data4insert(params["value"])
end

script = Script.new({
    "script" => __FILE__,
    "table" => "system_settings",
    "data_source" => method(:get_data),
    'sql_query' => 'INSERT INTO system_settings (param, value) VALUES (?, ?);',
    "thread_code" => method(:process)
})

