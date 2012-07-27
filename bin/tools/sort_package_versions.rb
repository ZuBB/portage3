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
require 'database'
require 'package'
require 'utils'

if ARGV.size == 0
    puts 'Error: pass package id or package name!'
    exit(1)
end

filename = '/dev/shm/test-20120724-221542.sqlite'
package_id_sql = 'select version from ebuilds where package_id=?'
package_sql = <<SQL
select version
from ebuilds e
join packages p on p.id=e.package_id
where package=?
SQL

Database.init(filename)

versions = []
separator = ', '

sql_query = Utils.is_number?(ARGV[0]) ? package_id_sql : package_sql
puts Database.select(sql_query, ARGV[0]).flatten.sort { |a,b|
    Package.vercmp(a ,b)
}.join(', ')
Database.close()

