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
    # TODO we need to add those as they are used later
    architectures = ['x64', 'sparc64']
    # name of the file to be processed
    filename = File.join(params['profiles2_home'], 'arch.list')

    # walk through all use lines in that file
    (IO.read(filename).to_a rescue []).each do |line|
        # break if we face with prefixes
        break if line.include?('# Prefix keywords')
        # skip comments
        next if line.start_with?('#')
        # skip empty lines, trim others and add them
        architectures << line.strip() unless line.match(/\S+/).nil?
    end

	return architectures
end

def process(params)
	Database.insert({
		'table' => params['table'],
		'data' => {'architecture' => params['value']}
	})
end

script = Script.new({
    'script' => __FILE__,
    'table' => 'architectures',
    'data_source' => method(:get_data),
    'thread_code' => method(:process)
})

