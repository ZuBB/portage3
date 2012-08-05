#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/09/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../../lib/common'))
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../../lib/portage'))
require 'ebuild_version'
require 'utils'

if ARGV.size == 0
    puts 'Error: required parameter is missing!'
    exit(1)
end

puts EbuildVersion.sort_versions_with_eix(ARGV[0]).join(', ')

