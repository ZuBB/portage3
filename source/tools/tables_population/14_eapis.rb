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
    queries_array = results = []
    # lets find all lines from all ebuilds that have EAPI string 0 position
    grep_command = "grep -h '^EAPI' #{params[:portage_home]}/*/*/*ebuild 2> /dev/null"

    for letter in 'a'..'z':
        results += %x[#{grep_command.sub(/\*/, "#{letter}*")}].split("\n")
    end

    results.map! { |line|
        line.sub(/#.*$/, '').gsub(/['" EAPI=]/, '')
    }

    results.uniq.compact.each { |eapi|
        # create query for eapi and add it into array
        queries_array << "INSERT INTO eapis (eapi_version) VALUES ('#{eapi}');"
    }

    params[:database].execute_batch(queries_array.join("\n"))
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)

