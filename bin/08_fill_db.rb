#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 6 01/06/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'common'))
require 'optparse'
require 'utils'

# hash with options
options = {"run_all" => true}

# lets merge stuff from tools lib
options.merge!(Utils::OPTIONS)
# get last created database
options["db_filename"] = Utils.get_last_created_database(options)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: purge_s3_data [options]\n"
    opts.separator " A script that purges outdated data from s3 bucket\n"

    opts.on("-a", "--[no-]run-all-scripts",
            "Run all scripts for populating db") do |value|
        options["run_all"] = value
    end

    opts.on("-f", "--database-file STRING",
            "Path where new database file will be created") do |value|
        # TODO check if path id valid
        options["db_filename"] = value
    end

    # parsing 'quite' option if present
    opts.on("-q", "--quiet", "Quiet mode") do |value|
        options["quiet"] = true
    end

    # parsing 'quite' option if present
    opts.on("-m", "--method STRING", "Parse method") do |value|
        options["method"] = value
    end

    # parsing 'untill' option if present
    opts.on("-u", "--run-untill STRING", "Run all scripts untill script with specified index") do |value|
        options["until"] = value
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

options["db_filename"] = ARGV[0] if ARGV.size == 1

plugins_dir = File.join(File.dirname(__FILE__), "tables_population")

if options["run_all"]
    Dir.glob(File.join(plugins_dir, "/*")).sort.each do |script|
        break if options["until"] && script.include?(options["until"])

        if (script.match(/\d\d_[a-z0-9_]+\.rb$/))
            command = "./#{script} -f #{options["db_filename"]}"
            command << " -m #{options["method"]}" if options["method"]
            # TODO: output, error_output, exit status, timeouts
            `#{command}`
        end
    end
end
