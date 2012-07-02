#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
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
	Database.insert({
		'table' => params['table'],
		'data' => {'source' => params['value']}
	})
end

script = Script.new({
    'script' => __FILE__,
    'table' => 'sources',
    'data_source' => method(:get_data),
    'thread_code' => method(:process)
})

