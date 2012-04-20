#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'tools'

# hash with options
options = Hash.new.merge!(OPTIONS)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: purge_s3_data [options]\n"
    opts.separator " A script that purges outdated data from s3 bucket\n"

    opts.on("-f", "--database-file STRING",
            "Path where new database file will be created") do |value|
        # TODO check if path id valid
        options[:db_filename] = value
    end

    #TODO do we need a setting `:root` option here?
    # parsing 'quite' option if present
    opts.on("-q", "--quiet", "Quiet mode") do |value|
        options[:quiet] = true
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get true portage home
portage_home = get_full_tree_path(options)
if options[:db_filename].nil?
    # get last created database
    options[:db_filename] = get_last_created_database(options)
end

sql_query01 = "SELECT value FROM system_settings WHERE param='arch';"
sql_query02 = "SELECT value FROM system_settings WHERE param='keyword';"
sql_query1 = "SELECT package_id FROM installed_apps"
sql_query2 = <<SQL
SELECT ebuilds.package_id, ebuilds.id, categories.category_name, packages.package_name, ebuilds.version
FROM categories, packages, ebuilds
WHERE
    ebuilds.package_id=? AND
    ebuilds.package_id = packages.id AND
    packages.category_id = categories.id
ORDER BY ebuilds.version_order DESC
SQL

sql_query3 = <<SQL
SELECT package_keywords.package_id, package_keywords.version
FROM package_keywords
WHERE
    package_keywords.package_id=? AND
    package_keywords.version=? AND
    package_keywords.arch_id = ? AND
    package_keywords.keyword_id = ?
ORDER BY package_keywords.id DESC
LIMIT 1
SQL

#SELECT COUNT(*)
sql_query41 = <<SQL
SELECT package_masks.package_id, package_masks.version
FROM package_masks
WHERE
    package_masks.package_id = ? and
    package_masks.version = ? and
    package_masks.arch_id = ?
SQL

sql_query42 = <<SQL
SELECT package_masks.source_id
FROM mask_states, package_masks
WHERE
    package_masks.package_id = ? AND
    package_masks.version = ? AND
    package_masks.arch_id = ? AND
    package_masks.mask_state_id =
        (SELECT id FROM mask_states WHERE mask_state=?)
SQL

found = nil
database = SQLite3::Database.new(options[:db_filename])
arch = database.get_first_value(sql_query01)
keyword = database.get_first_value(sql_query02)
database.execute(sql_query1) { |row_l1|
    database.execute(sql_query2, row_l1[0]) { |row_l2|
        found = false
        database.execute(sql_query3, row_l2[0], row_l2[1], arch, keyword) { |row_l3|
            res0 = database.execute(sql_query41, row_l3[0], row_l3[1], arch)
            if res0.size == 0
                puts "#{row_l2[2]}/#{row_l2[3]}-#{row_l2[4]}"
                found = true
                next
            end

            res1 = database.get_first_value(
                sql_query42, row_l3[0], row_l3[1], arch, 'unmasked'
            ) || 0
            res2 = database.get_first_value(
                sql_query42, row_l3[0], row_l3[1], arch, 'masked'
            ) || 0

            if res1 > res2
                puts "#{row_l2[2]}/#{row_l2[3]}-#{row_l2[4]}"
                found = true
            end
        }
        break if found
    }
}