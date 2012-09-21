#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../../lib/common'))
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'utils'

# hash with options
options = Hash.new.merge!(Utils::OPTIONS)

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
    opts.on("-d", "--debug", "Debug mode") do |value|
        options["debug"] = true
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get true portage home
if options[:db_filename].nil?
    # get last created database
    options[:db_filename] = Utils.get_last_created_database(options)
end

sql_query01 = "SELECT value FROM system_settings WHERE param='arch';"
sql_query02 = "SELECT value FROM system_settings WHERE param='keyword';"

sql_query1 = "SELECT package_id FROM installed_apps"
sql_query2 = <<SQL
SELECT e.id, c.category_name, p.package_name, e.version
FROM ebuilds e
JOIN packages p ON p.id=e.package_id
JOIN categories c ON c.id=p.category_id
WHERE e.package_id=?
ORDER BY e.version_order DESC
SQL

sql_query3 = <<SQL
SELECT ebuild_id
FROM ebuild_keywords
WHERE
    ebuild_id=? AND
    arch_id = ? AND
    keyword_id = ?
ORDER BY id DESC
LIMIT 1
SQL

sql_query41 = <<SQL
SELECT count(id)
FROM ebuild_masks
WHERE
    ebuild_id = ? and
    mask_state_id = (SELECT id FROM mask_states WHERE mask_state='masked')
SQL

sql_query42 = <<SQL
SELECT MAX(source_id)
FROM ebuild_masks
WHERE
    ebuild_id = ? AND
    arch_id = ? AND
    mask_state_id = (SELECT id FROM mask_states WHERE mask_state=?)
SQL

found = nil
database = SQLite3::Database.new(options[:db_filename])
arch = database.get_first_value(sql_query01)
keyword = database.get_first_value(sql_query02)
database.execute(sql_query1) { |row_l1|
    p '='*40 if options['debug']
    p row_l1 if options['debug']
    database.execute(sql_query2, row_l1[0]) { |row_l2|
        p '*'*30 if options['debug']
        p row_l2 if options['debug']
        found = false
        database.execute(sql_query3, row_l2[0], arch, keyword) { |row_l3|
            p '+'*20 if options['debug']
            p row_l3 if options['debug']
            res0 = database.get_first_value(sql_query41, row_l2[0])
            p "res0: #{res0}" if options['debug']
            if res0.to_i == 0
                p '"no masked" match' if options['debug']
                puts "#{row_l2[1]}/#{row_l2[2]}-#{row_l2[3]}"
                found = true
                next
            end

            res1 = database.get_first_value(
                sql_query42, row_l2[0], arch, 'unmasked'
            ) || 0
            p "res1: #{res1}" if options['debug']
            res2 = database.get_first_value(
                sql_query42, row_l2[0], arch, 'masked'
            ) || 0
            p "res2: #{res2}" if options['debug']

            if res1.to_i > res2.to_i
                p '"unmasked" match' if options['debug']
                puts "#{row_l2[1]}/#{row_l2[2]}-#{row_l2[3]}"
                found = true
            end
        }
        break if found
    }
}
