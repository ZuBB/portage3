#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
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

    opts.on("-r", "--root-folder STRING",
            "Dir where portage database will be created") do |value|
        options[:storage][:root] = File.expand_path(value)
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

# get true portage home
portage_home = get_full_tree_path(options)
if options[:db_filename].nil?
	# get last created database
	options[:db_filename] = get_last_created_database(options)
end

def fill_table(database, portage_home)
    # array of all inserts
    queries_array = []
    # walk through all items in architectures dir
    Dir.new(File.join(portage_home, "profiles/arch")).sort.each do |arch|
        # skip system dirs
        next if ['.', '..'].index(arch) != nil
        # create query for current arch
        query = "INSERT INTO architectures (architecture) VALUES ('#{arch}');"
        # add query into array
        queries_array << query
    end

    database.execute_batch(queries_array.join("\n"))
end

fill_table_X(
    options[:db_filename],
	File.basename(__FILE__).match(/^\d\d_([a-z]+)\.rb$/)[1].to_s,
	method(:fill_table),
	[portage_home]
)
