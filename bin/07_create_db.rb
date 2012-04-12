#!/usr/bin/env ruby
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'utils'

# hash with default settings
options = {
    "sql_src_home" => '../sql',
    "sql_src" => 'portage.sqlite.sql',
    "batch_mode" => false,
    "verbose" => false,
    "list" => false,
# lets merge stuff from tools lib
}.merge!(Utils::OPTIONS)

# db_filename
db_filename = "test-#{Utils.get_timestamp()}.sqlite"

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: create_db [options]\n"
    opts.separator " Creates empty database file for Gentoo portage\n"

    # parsing 'provide_listing' option if present
    opts.on("-l", "--list-recent", "List recent dbs") do |value|
        options["list"] = true
    end

    # parsing 'batch_mode' option if present
    opts.on("-b", "--batch-mode", "Batch mode") do |value|
        options["batch_mode"] = true
        options["list"] = false
    end

    # parsing 'root' option if present
    opts.on("-r", "--root-dir STRING", "Dir where new database file will be located") do |base_dir|
        unless File.exists?(base_dir)
            puts "ERROR: directory '#{base_dir}' does not exist!"
            exit(1)
        end

        unless File.writable?(base_dir)
            puts "ERROR: directory '#{base_dir}' is not writable!"
            exit(1)
        end

        options["storage"]["root"] = base_dir
    end

    # parsing 'db_filename' option if present
    opts.on("-f", "--database-file STRING", "Path to new database file") do |value|
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
        options["list"] = false
    end

    # parsing 'verbose' option if present
    opts.on("-v", "--verbose", "Versbose mode") do |value|
        options["verbose"] = true
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get path to the database file
db_path = File.join(options["portage_home"], db_filename)

begin
    db = SQLite3::Database.new(db_path)
    db.execute_batch(IO.read(File.join(
        File.dirname(__FILE__),
        options["sql_src_home"],
        options["sql_src"]
    )))

    puts "Everything is OK. Database was created at:\n#{db_path}"

    if options["list"]
        path = File.join(options["portage_home"], "*.sqlite")
        puts "\n#{`ls -l #{path} | tail -n 10`}"
    end
rescue Exception => msg
    File.delete(db_path) if File.exists?(db_path)
    puts msg
ensure
    db.close() if db.closed? == false
end
