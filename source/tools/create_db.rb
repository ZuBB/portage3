#!/usr/bin/env ruby
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'tools'

# hash with default settings
options = {
    :sql_src_home => '../sql',
    :sql_src => 'portage.sqlite.sql',
    :sql_extra_src => 'notes.sqlite.sql',
    :db_path => nil,
    :batch_mode => false,
    :verbose => false,
    :list => false,
    :extra => true
# lets merge stuff from tools lib
}.merge!(OPTIONS)
# db_filename
options[:db_filename] = "test-#{get_timestamp()}.sqlite"

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: create_db [options]\n"
    opts.separator " Creates empty database file for Gentoo portage\n"

    # parsing 'provide_listing' option if present
    opts.on("-l", "--list-recent", "List recent dbs") do |value|
        options[:list] = true
    end

    # parsing 'batch_mode' option if present
    opts.on("-b", "--batch-mode", "Batch mode") do |value|
        options[:batch_mode] = true
        options[:list] = false
    end

    # parsing 'root' option if present
    opts.on("-r", "--root-dir STRING", "Dir where new database file will be located") do |base_dir|
        if !File.exists?(base_dir)
            puts "ERROR: directory '#{base_dir}' does not exist!"
            exit(1)
        end

        if !File.writable?(base_dir)
            puts "ERROR: directory '#{base_dir}' is not writable!"
            exit(1)
        end

        options[:storage][:root] = base_dir
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
 
        options[:db_filename] = value
        options[:list] = false
    end

    # parsing 'verbose' option if present
    opts.on("-v", "--verbose", "Versbose mode") do |value|
        options[:verbose] = true
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get sql code
sql = IO.read(File.join(
    File.dirname(__FILE__),
    options[:sql_src_home],
    options[:sql_src]
))

sql_extra = IO.read(File.join(
    File.dirname(__FILE__),
    options[:sql_src_home],
    options[:sql_extra_src]
))

# get path to the database file
options[:db_path] = File.join(
    options[:storage][:root],
    options[:storage][:home_folder],
    options[:db_filename]
)
# some var definition
error_code, message = 0, 'Everything is OK. Database was created at:'
# print sql if verbose is set
puts '='*30, sql, '='*30 if options[:verbose]

begin
    db = SQLite3::Database.new(options[:db_path])
    db.execute_batch(sql)
    db.execute_batch(sql_extra) if options[:extra]

    if File.size(options[:db_path]) == 0
        message = 'Something went wrong. created db has zero size'
        error_code = 2
    end
rescue Exception => msg
    File.delete(options[:db_path])
    message = msg
    error_code = 1
ensure
    db.close() if db.closed? == false
end

puts message if !options[:batch_mode]
puts options[:db_path] if error_code == 0

if options[:list]
    path = File.join(
        options[:storage][:root],
        options[:storage][:home_folder],
        "*.sqlite"
    )
    puts "\n#{`ls -l #{path} | tail -n 10`}"
end

exit(error_code)