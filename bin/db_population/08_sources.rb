#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []

    Dir[File.join(params['profiles2_home'], '**/*/')].each do |dir|
        next unless dir.include?('/base/')
        next if File.exist?(File.join(dir, 'deprecated'))
        results << dir.sub(params['profiles2_home'] + '/', '')
    end

    results.unshift('ebuilds') + ['/etc/make.conf', '/etc/portage/', 'CLI']
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO sources (source) VALUES (?);'
})

