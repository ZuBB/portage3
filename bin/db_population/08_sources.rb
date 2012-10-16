#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

SOURCES = [
    'ebuilds', 'profiles', '/etc/make.conf', '/etc/portage', 'CLI', '/var/db/pkg'
]

def get_data(params)
    results = Array.new + SOURCES[0..1]

    # TODO this has been commited because we decided to go with
    # stock profiles for 1st version
    if false
        Dir[File.join(params['profiles_home'], '**/*/')].each do |dir|
            next unless dir.include?('/base/')
            next if File.exist?(File.join(dir, 'deprecated'))
            results << dir.sub(params['profiles_home'] + '/', '')
        end
    end

    results += SOURCES[2..-1]
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO sources (source) VALUES (?);'
})

