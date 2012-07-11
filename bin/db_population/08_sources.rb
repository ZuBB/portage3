#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'

def get_data(params)
    # result here
    sources = []

    # walk through all dirs in profiles dir
    Dir[File.join(params['profiles2_home'], '**/*/')].each do |dir|
        # skip dirs that not in base
        next unless dir.include?('/base/')
        # skip dirs that not in base
        next if File.exist?(File.join(dir, 'deprecated'))
        # lets remember this
        sources << dir.sub(params['profiles2_home'] + '/', '')
    end

    sources.unshift('ebuilds') + ['/etc/make.conf', '/etc/portage/', 'CLI']
end

def process(params)
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO sources (source) VALUES (?);'
})

