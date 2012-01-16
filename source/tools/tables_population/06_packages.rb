#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'optparse'
require 'rubygems'
require 'nokogiri'
require 'sqlite3'
require 'tools'

# hash with options
options = {
    :db_filename => nil,
    :storage => {},
    :quiet => true
}

# lets merge stuff from tools lib
options[:storage].merge!(STORAGE)
# get last created database
options[:db_filename] = get_last_created_database(
    options[:storage][:root],
    options[:storage][:home_folder]
)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: purge_s3_data [options]\n"
    opts.separator " A script that purges outdated data from s3 bucket\n"

    opts.on("-f", "--database-file STRING", "Path where new database file will be created") do |value|
        # TODO check if path id valid
        options[:db_filename] = value
    end

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

def is_package_invalid(item_path, package)
    # skip system dirs
    return true if ['.', '..'].index(package) != nil
    # skip if it is a file
    return true if  File.file?(item_path)
    # valid one! :)
    return false
end

def fill_packages_table(database, portage_home)
    Dir.new(portage_home).sort.each do |category|
        # check if current item is valid for us
        next if is_category_invalid(portage_home, category)

        # get id of the current category from our db
        sql_query = "SELECT id FROM categories WHERE category_name=?;"
        category_id = database.execute(sql_query, category)[0]

        # lets walk through all items in category dir
        Dir.new(File.join(portage_home, category)).sort.each do |package|
            # lets get full path for this item
            item_path = File.join(portage_home, category, package)
            # skip if it is a ..
            next if is_package_invalid(item_path, package)

            # get content of the last ebuild for this package
            ebuild_text = IO.read(Dir.glob(item_path + '/*.ebuild').sort.last).to_a
            description = get_ebuild_description(ebuild_text)
            homepage = get_ebuild_homepage(ebuild_text)

            sql_query = <<SQL
    INSERT INTO packages
    (category_id, package_name, description, homepage)
    VALUES (?, ?, ?, ?);
SQL
            database.execute(sql_query, category_id, package, description, homepage)
        end
    end
end

fill_packages_table(db, portage_home)
