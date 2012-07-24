#!/usr/bin/env ruby
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'common'))
#require 'optparse'
#require 'database'
#require 'utils'

puts 'TODO: implementation missed :)'

'.timer ON'
R = [
<<QUERIES

select flag_name, count(*)
from use_flags
group by flag_name
having count(*) > 1

total categories
top 5 categories with max packages
top 5 categories with min packages
total packages
top 5 packages with max ebuilds
top 5 packages with min ebuilds
total ebuilds
top 5 newest changed ebuilds
top 5 oldest changed ebuilds
top 5 authors that change max ebuilds
top 5 authors that change min ebuilds
total slots
top 5 slots by max amount of ebuilds
top 5 slots by min amount of ebuilds
total descriptions
top 5 descriptions that is widely used
top 5 descriptions that is seldomly used
amount of packages where amount of descriptions > 1
top 5 packages with max amount of descriptions
total homepages
top 5 most used homepages
top 5 rare used homepages
amount of packages where amount of homepage % amount of ebuilds != 0
top 5 packages with max (where amount of homepage % amount of ebuilds)
top 5 most stable arches
top 5 most unstable arches
amount of packages that has at least one stable ebuild
amount of packages that does not have stable ebuilds
top 5 most masked arches
top 5 most unmasked arches
amount of packages that has at least one ebuild masked for any arch
amount of packages that does not have unmasked ebuilds
total use_flags by type
top 5 packages with max ebuilds
top 5 widely used use_flags
top 5 packages with max use_flags enabled
top 5 packages with max use_flags disabled
total licences
top 5 most used licences
top 5 rare used licences
top by amount of used licences 
total records
QUERIES
]

