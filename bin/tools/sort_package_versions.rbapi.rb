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
require 'database'
require 'utils'

if ARGV.size == 0
    puts 'Error: required parameter is missing!'
    exit(1)
end

versions = []
if ARGV.size == 1
    versions = ARGV[0].split(',')
else
    Database.init(ARGV[0])
    package_id_sql = 'select version from ebuilds where package_id=?'
    package_sql = <<-SQL
        select version
        from ebuilds e
        join packages p on p.id=e.package_id
        join categories c on c.id=p.category_id
        where c.name=? and p.name=?"""
    SQL
    if Utils.is_number?(ARGV[0])
        versions = Database.select(package_id_sql, ARGV[1])
    else
        params = ARGV[1].split('/')
        versions = Database.select(package_sql, params[0], params[1])
    end
    versions = versions.flatten
    Database.close()
end

puts versions.sort { |a,b|
    EbuildVersion.compare_versions_with_rbapi(a ,b)
}.join(', ')

