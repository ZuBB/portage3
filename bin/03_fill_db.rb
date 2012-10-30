#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 6 01/06/12
# Latest Modification: Vasyl Zuzyak, ...
#
current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib', 'common'))
$:.push File.expand_path(File.join(current_dir, '..', 'lib', 'portage'))
$:.push File.expand_path(File.join(current_dir, '..', 'tasks'))

require 'optparse'
require 'tasks'
require 'scheduler'

# hash with options
options = {
    "from" => 1,
    "until" => 999,
    "skip" => [],
    "task_filenames" => []
}

# get default options
options.merge!(Utils::OPTIONS)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: 03_fill_db [options]\n"
    opts.separator " A script that fills cache db with data"

    # parsing 'threads' option if present
    opts.on("-1", "--one-thread", "Use 1 thread for processing") do
        options["threads"] = 1
    end

    opts.on("-f", "--database-file STRING", "Path to database file to fill") do |value|
        # TODO check if path id valid
        options["db_filename"] = value
    end

    # parsing 'debug' option if present
    opts.on("-d", "--debug", "Set log level to 'debug'") do |value|
        options["debug"] = true
    end

    # parsing 'log-device' option if present
    opts.on("--log-device STRING", "Your custom log device. Applies only if '-t' option is used") do |value|
        options["log-device"] = value
    end

    # parsing 'method' option if present
    opts.on("-m", "--method STRING", "Parse method") do |value|
        options["method"] = value
    end

    # parsing 'from' option if present
    opts.on("-r", "--from STRING", "Start from specified script") do |value|
        options["from"] = value.to_i
    end

    # parsing 'skip' option if present
    opts.on("-s", "--skip STRING", "Skip specified scripts") do |value|
        options["skip"] = value.split(',').map { |i| i.strip.to_i }
    end

    # parsing 'untill' option if present
    opts.on("-u", "--run-untill STRING", "Run all scripts untill script with specified index") do |value|
        options["until"] = value.to_i
    end

    # parsing 'task' option if present
    opts.on("-t", "--task STRING", "Run the task with specified index. Overrides any of '-r', '-s', '-u'") do |value|
        options["skip"] = []
        options["from"] = value.to_i
        options["until"] = value.to_i + 1
    end

    # parsing 'quite' option if present
    opts.on("-q", "--[no-]quiet", "Quiet mode") do |value|
        options["quiet"] = value
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

scripts_dir = File.join(File.dirname(__FILE__), "../tasks")

Dir.glob(File.join(scripts_dir, "/*.rb")).sort.each do |script|
    task_filename = File.basename(script)
    if /\d{3}_[\w_]+\.rb$/ =~ task_filename
        options['task_filenames'] << task_filename
        require_relative script
    end
end

filler = Tasks::Scheduler.new(options)
filler.get_dependencies
filler.build_dependency_tree
filler.start_specified_tasks

