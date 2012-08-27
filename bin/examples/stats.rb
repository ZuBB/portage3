#!/usr/bin/env ruby
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../lib/common'))
require 'optparse'
require 'sqlite3'
#require 'utils'

REPORTS = [
    {
        'descr' => 'Total categories',
        'query' => 'select count(id) from categories;'
    },
    {
        'descr' => 'Top 5 categories with max packages',
        'query' => <<-SQL
            select c.name, count(p.id) as packages_count
            from packages p
            join categories c on p.category_id=c.id
            group by p.category_id
            order by packages_count desc
            limit 5;
        SQL
    },
    {
        'descr' => 'Top 5 categories with min packages',
        'query' => <<-SQL
            select c.name, count(p.id) as packages_count
            from packages p
            join categories c on p.category_id=c.id
            group by p.category_id
            order by packages_count asc
            limit 5;
        SQL
    },
    {
        'descr' => 'Total packages',
        'query' => 'select count(id) from packages;'
    },
    {
        'descr' => 'Top packages by amount of ebuilds per package',
        'query' => <<-SQL
            select ebuilds_count as ebuilds_per_package, count(id) as packages
            from (
                SELECT p.id, COUNT(e.id) AS ebuilds_count
                FROM ebuilds e
                JOIN packages p ON e.package_id=p.id
                GROUP BY p.package_id
                ORDER BY ebuilds_count ASC
            ) em
            group by ebuilds_count
            order by packages desc;
        SQL
    },
    {
        'descr' => 'Packages without ebuilds',
        'query' => <<-SQL
            select c.category_name, p.name
            from packages p
            join categories c on p.category_id=c.id
            where p.id not in (select package_id from ebuilds)
            order by c.category_name, p.name asc;
        SQL
    },
    {
        'descr' => 'Total ebuilds',
        'query' => 'select count(id) from ebuilds;'
    },
    {
        'descr' => 'Top 5 newest ebuilds',
        'query' => <<-SQL
            select c.name, p.name, e.version, e.mtime
            from ebuilds e
            join packages p on e.package_id=p.id
            join categories c on p.category_id=c.id
            order by e.mtime desc
            limit 5;
        SQL
    },
    {
        'descr' => 'Top 5 oldest ebuilds',
        'query' => <<-SQL
            select c.name, p.name, e.version, e.mtime
            from ebuilds e
            join packages p on e.package_id=p.id
            join categories c on p.category_id=c.id
            order by e.mtime asc
            limit 5;
        SQL
    },
    {
        'descr' => 'Top 5 authors that change max amount of ebuilds',
        'query' => <<-SQL
            select mauthor, count(e.id) as ebuilds_count
            from ebuilds
            group by mauthor.
            order by ebuilds_count desc
            limit 5;
        SQL
    },
    {
        'descr' => 'Top packages by amount of ebuilds per package',
        'descr' => 'Top ebuilds by amount of ebuilds per package',
        # top 5 authors that change min ebuilds
        'query' => <<-SQL
            select ebuilds_count as ebuilds_per_package, count(id) as packages
            from (
                SELECT p.id, COUNT(e.id) AS ebuilds_count
                FROM ebuilds e
                JOIN packages p ON e.package_id=p.id
                GROUP BY p.package_id
                ORDER BY ebuilds_count ASC
            ) em
            group by ebuilds_count
            order by packages desc;
        SQL
    },
]

DESCRIPTIONS = <<TXT
total eapis
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
licences that does not belong to any group
licence groups that does not have any licence in it
top 5 most used licences
top 5 rare used licences
top by amount of used licences 
total records
TXT

#select flag_name, count(*)
#from use_flags
#group by flag_name
#having count(*) > 1

#test.each { |block|
    #puts block['descr']
    #res = database.execute2(block['query'])
    #puts res.to_table(:first_row_is_head => true).to_s
#}

