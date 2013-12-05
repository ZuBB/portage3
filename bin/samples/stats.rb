#!/usr/bin/env ruby
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../../lib'))

require 'optparse'
require 'portage3'
require 'text-table'

REPORTS = [
    {
        'descr' => 'Total categories',
        'query' => <<-SQL
            select 'categories' as entity, count(id) as amount
            from categories;
        SQL
    },
    {
        'descr' => 'Top 5 categories with max packages',
        'query' => <<-SQL
            select c.name as category, count(p.id) as packages
            from packages as p
            join categories c on p.category_id=c.id
            where p.source_id = 1
            group by p.category_id
            order by packages desc
            limit 5;
        SQL
    },
    {
        'descr' => 'Top 5 categories with min packages',
        'query' => <<-SQL
            select c.name as category, count(p.id) as packages
            from packages as p
            join categories c on p.category_id=c.id
            where p.source_id = 1
            group by p.category_id
            order by packages asc
            limit 5;
        SQL
    },
    {
        'descr' => 'Total packages',
        'query' => <<-SQL
            select 'packages' as entity, count(id) as amount from packages;
        SQL
    },
    {
        'descr' => 'Packages by amount of ebuilds per package',
        'query' => <<-SQL
            SELECT count(id) AS packages, ebuilds AS 'ebuilds per package'
            FROM (
                SELECT e.package_id as id, COUNT(e.id) AS ebuilds
                FROM ebuilds AS e
                WHERE e.source_id == 2
                GROUP BY e.package_id
            ) em
            GROUP BY ebuilds
            ORDER BY ebuilds DESC;
        SQL
    },
    {
        'descr' => 'Top 5 packages by amount of ebuilds per package',
        'query' => <<-SQL
            SELECT c.name || '/' || p.name AS package, COUNT(e.id) AS ebuilds
            FROM ebuilds AS e
            JOIN packages p ON e.package_id=p.id
            JOIN categories c ON p.category_id=c.id
            GROUP BY e.package_id
            ORDER BY ebuilds DESC
            LIMIT 5;
        SQL
    },
    {
        'descr' => 'Total ebuilds',
        'query' => <<-SQL
            select 'ebuilds' as entity, count(id) as amount
            from ebuilds
            where source_id = 2;
        SQL
    },
    {
        'descr' => 'Top 5 newest ebuilds',
        'query' => <<-SQL
            select
                c.name || '/' || p.name || '-' || e.version AS ebuild,
                e.mtime as date
            from ebuilds e
            join packages p on e.package_id=p.id
            join categories c on p.category_id=c.id
            where e.source_id == 2
            order by e.mtime desc
            limit 5;
        SQL
    },
    {
        'descr' => 'Top 5 oldest ebuilds',
        'query' => <<-SQL
            select
                c.name || '/' || p.name || '-' || e.version AS ebuild,
                e.mtime as date
            from ebuilds e
            join packages p on e.package_id=p.id
            join categories c on p.category_id=c.id
            where e.source_id == 2
            order by e.mtime asc
            limit 5;
        SQL
    },
    {
        'descr' => 'Top 5 ebuild committers',
        'query' => <<-SQL
            select mauthor as committer, count(e.id) as ebuilds
            from ebuilds as e
            where e.source_id == 2
            group by mauthor
            order by ebuilds desc
            limit 5;
        SQL
    },
    {
        'descr' => 'Most inactive contributors by ebuild commits',
        'query' => <<-SQL
            select mauthor as contributor, count(e.id) as commits
            from ebuilds as e
            where e.source_id == 2
            group by mauthor
            having count(e.id) < 4
            order by commits;
        SQL
    },
    { 'descr' => 'total eapis' },
    { 'descr' => 'total slots' },
    { 'descr' => 'top 5 slots by max amount of ebuilds' },
    { 'descr' => 'top 5 slots by min amount of ebuilds' },
    { 'descr' => 'total descriptions' },
    { 'descr' => 'top 5 descriptions that is widely used' },
    { 'descr' => 'top 5 descriptions that is seldomly used' },
    { 'descr' => 'amount of packages where amount of descriptions > 1' },
    { 'descr' => 'top 5 packages with max amount of descriptions' },
    { 'descr' => 'total homepages' },
    { 'descr' => 'top 5 most used homepages' },
    { 'descr' => 'top 5 rare used homepages' },
    { 'descr' => 'amount of packages where amount of homepage % amount of ebuilds != 0' },
    { 'descr' => 'top 5 packages with max (where amount of homepage % amount of ebuilds)' },
    { 'descr' => 'top 5 most stable arches' },
    { 'descr' => 'top 5 most unstable arches' },
    { 'descr' => 'amount of packages that has at least one stable ebuild' },
    { 'descr' => 'amount of packages that does not have stable ebuilds' },
    { 'descr' => 'top 5 most masked arches' },
    { 'descr' => 'top 5 most unmasked arches' },
    { 'descr' => 'amount of packages that has at least one ebuild masked for any arch' },
    { 'descr' => 'amount of packages that does not have unmasked ebuilds' },
    { 'descr' => 'total use_flags by type' },
    { 'descr' => 'top 5 packages with max ebuilds' },
    { 'descr' => 'top 5 widely used use_flags' },
    { 'descr' => 'top 5 packages with max use_flags enabled' },
    { 'descr' => 'top 5 packages with max use_flags disabled' },
    { 'descr' => 'total licences' },
    { 'descr' => 'licences that does not belong to any group' },
    { 'descr' => 'licence groups that does not have any licence in it' },
    { 'descr' => 'top 5 most used licences' },
    { 'descr' => 'top 5 rare used licences' },
    { 'descr' => 'top by amount of used licences ' },
    { 'descr' => 'total records' }
]

Portage3::Logger.start_server
Portage3::Database.init(Utils.get_database)
database = Portage3::Database.get_client

REPORTS.each_with_index { |report, index|
    next unless report.has_key?('query')

    result = database.execute2(report['query'])
    next if result.size == 1

    if %w(newest oldest).any? { |w| report['descr'].include?(w) }
        result.each_with_index { |row, index|
            next if index == 0
            row[row.size - 1] = Time.at(row.last.to_i).to_s
        }
    end

    puts (' ' * 3) + report['descr']
    puts result.to_table(:first_row_is_head => true).to_s
    puts
}

database.shutdown_server

