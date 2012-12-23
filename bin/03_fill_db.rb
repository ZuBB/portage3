#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 6 01/06/12
# Latest Modification: Vasyl Zuzyak, ...
#
current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))
$:.push File.expand_path(File.join(current_dir, '..', 'lib', 'portage'))
$:.push File.expand_path(File.join(current_dir, '..', 'tasks'))

require 'optparse'
require 'portage3'
require 'tasks'

def create_database(db_filename, sql_src_home, quiet, only_db)
    # get path to the database file
    db_path = File.join(Utils.get_db_home, db_filename)
    sql_home = File.join(File.dirname(__FILE__), sql_src_home)
    sql_filename = Dir.glob(File.join(sql_home, '*sql'))[0]

    Portage3::Logger.start_server
    db_client = Portage3::Database.get_client({'db_filename' => db_path})

    if (result = db_client.safe_execute(IO.read(sql_filename))) && !only_db
        action = 'commit_transaction'
    else
        action = 'shutdown_server'
        only_db = true
    end

    db_client.send(action)
    Portage3::Logger.shutdown_server if only_db

    result ? (only_db ? true : db_client) : sql_filename
end

def fill_database(options)
    scripts_dir = File.join(File.dirname(__FILE__), "../tasks")

    Dir.glob(File.join(scripts_dir, "/*.rb")).sort.each do |script|
        task_filename = File.basename(script)
        if /\d{3}_[\w_]+\.rb$/ =~ task_filename
            options['task_filenames'] << task_filename
            require_relative(script)
        end
    end

    filler = Tasks::Scheduler.new(options)
    filler.run_specified_tasks
    filler.finalize
end

# hash with options
options = {
    "from" => 1,
    "until" => 999,
    "skip" => [],
    "task_filenames" => [],
    "show_db" => true,
    "sql_src_home" => '../sql'
}

# get default options
options.merge!(Utils::OPTIONS)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: 03_fill_db [options]\n"
    opts.separator " A script that fills cache db with data"

    # parsing 'db_filename' option if present
    opts.on("-f", "--database-file STRING", "Custom path to new database file") do |value|
        if File.exists?(value)
            puts "ERROR: file '#{value}' already exists!"
            exit(1)
        end

        base_dir = File.dirname(value)

        if !File.exists?(base_dir)
            puts "ERROR: directory '#{base_dir}' does not exist!"
            exit(1)
        end

        if !File.writable?(base_dir)
            puts "ERROR: directory '#{base_dir}' is not writable!"
            exit(1)
        end

        value << '.sqlite' if File.extname(value) != 'sqlite'

        options["db_filename"] = value
    end

    # parsing 'create-database' option if present
    opts.on("-c", "--create-database", "Create new sqlite database. "\
            "Otherwise previous one will be used") do |value|
        options["new_db"] = true
    end

    # parsing 'only-database' option if present
    opts.on("-C", "--only-database", "Only create db, do not fill. Implies '-c'") do |value|
        options["new_db"] = true
        options["only_db"] = true
    end

    # parsing 'debug' option if present
    opts.on("-d", "--debug", "Set log level to 'debug'") do |value|
        options["debug"] = true
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
        options["skip"] = value
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

if options["new_db"]
    db_filename = Portage3::Database.create_db_name
    connection = create_database(
        db_filename,
        options['sql_src_home'],
        options['quiet'],
        options['only_db']
    )

    if options['only_db'] && connection == true
        puts "Everything is OK. Database was created at:\n#{db_filename}"
    elsif options['only_db'] && connection.is_a?(String)
        puts "SQL statements in '#{connection}' have error(s)"
    end
end

unless options['only_db']
    options['connection'] = connection if options["new_db"]
    if options["new_db"]
        options['db_filename'] = File.join(Utils.get_db_home, db_filename)
    end

    fill_database(options)
    message = ['Everything is OK. Database was']
    message << 'created' if options['new_db']
    message << 'and' if options['new_db'] && !options['only_db']
    message << 'filled' unless options['only_db']
    message << "at \n#{options['db_filename']}"
    puts message.join(' ')
end

