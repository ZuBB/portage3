#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/07/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'parser'

script = Script.new({
    "script" => __FILE__,
    "table" => "system_settings",
    "helper_query1" => "SELECT id FROM arches WHERE arch_name=?",
    "helper_query2" => "SELECT id FROM keywords WHERE keyword=?"
})

def fill_table(params)
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

    Database.insert({
        "table" => params["table"],
        "data" => {
            "param" => 'arch_id',
            "value" => Database.get_1value(params["helper_query1"], arch_name)
        }
    })

    Database.insert({
        "table" => params["table"],
        "data" => {
            "param" => 'keyword_id',
            "value" => Database.get_1value(params["helper_query2"], keyword_name)
        }
    })
end

script.fill_table_X(method(:fill_table))

