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

def fill_table(params)
    sql_query = "INSERT INTO profile_statuses (profile_status) VALUES (?);"
    path = File.join(params[:portage_home], "profiles", "profiles.desc")
    return if !File.readable?(path)
    # lets find all lines from profiles.desc file
    results = %x[grep -oP '\t[a-z]*$' #{path}].to_a rescue []
    # drop first item since its a header
    results.shift()

    results.uniq.compact.each { |status|
        params[:database].execute(sql_query, status.strip!())
    }
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)
