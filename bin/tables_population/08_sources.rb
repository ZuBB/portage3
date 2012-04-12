#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'fileutils'

script = Script.new({
    "table" => "sources",
    "script" => __FILE__
})

def fill_table(params)
    filepath = File.join(params["portage_home"], "profiles_v2")
    FileUtils.cd(filepath)
    sources = ['ebuilds']

    # walk through all use flags in that file
    Dir['**/*/'].each do |dir|
        # skip dirs that not in base
        next unless dir.include?('base')
        # skip dirs that not in base
        next if File.exist?(File.join(filepath, dir, 'deprecated'))

        # lets remember this
        sources << dir
    end

    sources += ['/etc/make.conf', '/etc/portage/', 'CLI']
    sources.each { |item|
        Database.insert({
            "table" => params["table"],
            "data" => {"source" => item}
        })
    }
end

script.fill_table_X(method(:fill_table))

