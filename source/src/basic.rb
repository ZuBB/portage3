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

filename = "/var/lib/portage/world"
file_content = IO.read(filename).to_a rescue []
sql_query1 = "SELECT package_id FROM installed_apps"
sql_query2 = <<SQL
SELECT categories.category_name, packages.package_name, ebuilds.version
FROM categories, packages, ebuilds, ebuilds2architectures, ebuild_arch2keywords
WHERE
    ebuilds.package_id=? and
    ebuilds.package_id = packages.id and
    packages.category_id = categories.id and 
    ebuilds.id = ebuilds2architectures.ebuild_id and 
    ebuilds2architectures.architecture_id=(
        SELECT id FROM architectures WHERE architecture=?
    ) and
    ebuilds2architectures.id = ebuild_arch2keywords.ebuild_arch_id and
    ebuild_arch2keywords.keyword_id = (
        SELECT id FROM keywords WHERE keyword=?
    )
ORDER BY ebuilds.version DESC
LIMIT 1
SQL

database = SQLite3::Database.new(options[:db_filename])
database.execute(sql_query1) do |row|
    database.execute(sql_query2, row[0], 'x86', 'stable') do |row1|
        puts "=#{row1[0]}/#{row1[1]}-#{row1[2]}"
    end
end

