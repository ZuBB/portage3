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
options = Hash.new.merge!(Utils::OPTIONS)
# get last created database
options["db_filename"] = Utils.get_database()

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: 03_fill_db [options]\n"
    opts.separator " A script that fills cache db with all data"

    opts.on("-f", "--database-file STRING",
            "Path to database file to fill") do |value|
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
    opts.on("-r", "--from STRING", "Start from specified script") do |value|
        options["from"] = value.to_i
    end

    # parsing 'untill' option if present
    opts.on("-s", "--skip STRING", "Skip specified scripts") do |value|
        options["skip"] = value.split(',').map { |i| i.strip.to_i }
    end

    # parsing 'untill' option if present
    opts.on("-u", "--run-untill STRING", "Run all scripts untill script with specified index") do |value|
        options["until"] = value.to_i
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

options["db_filename"] = ARGV[0] if ARGV.size == 1

scripts_dir = File.join(File.dirname(__FILE__), "db_population")

Dir.glob(File.join(scripts_dir, "/*.rb")).sort.each do |script|
    next unless /\d\d_[\w_]+\.rb$/ =~ script

    number = File.basename(script).match(/^\d\d/).to_a[0].to_i
    next if options["from"] && number < options["from"] 
    break if options["until"] && number >= options["until"] 
    next if options['skip'] && options['skip'].include?(number)

    command = "./#{script} -f #{options["db_filename"]}"
    command << " -m #{options["method"]}" if options["method"]
    # TODO: output, error_output, exit status, timeouts
    `#{command}`
end

