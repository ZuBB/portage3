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
require 'tools'

# hash with options
options = {
    :run_all => true
}

# lets merge stuff from tools lib
options.merge!(OPTIONS)
# get last created database
options[:db_filename] = get_last_created_database(options)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: purge_s3_data [options]\n"
    opts.separator " A script that purges outdated data from s3 bucket\n"

    opts.on("-a", "--[no-]run-all-scripts",
            "Run all scripts for populating db") do |value|
        options[:run_all] = value
    end

    opts.on("-f", "--database-file STRING",
            "Path where new database file will be created") do |value|
        # TODO check if path id valid
        options[:db_filename] = value
    end

    # TODO run custom set of scripts
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

options[:db_filename] = ARGV[0] if ARGV.size == 1

plugins_dir = File.join(File.dirname(__FILE__), "tables_population")

if options[:run_all]
    Dir.glob(File.join(plugins_dir, "/*")).sort.each do |script|
		if (script.match(/\d\d_[a-z_\-]+\.rb$/))
			# TODO: output, error_output, exit status, timeouts
			`./#{script} -f #{options[:db_filename]}`
		end
	end
end
