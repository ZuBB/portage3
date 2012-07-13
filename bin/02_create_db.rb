#!/usr/bin/env ruby
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'common'))
require 'optparse'
require 'database'
require 'utils'

# hash with default settings
options = {
    "sql_src_home" => '../sql',
# lets merge stuff from tools lib
}.merge!(Utils::OPTIONS)

# db_filename
db_filename = "test-#{Utils.get_timestamp()}.sqlite"

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: 02_create_db [options]\n"
    opts.separator " Creates empty database file for Gentoo portage cache\n"

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
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get path to the database file
db_path = File.join(Utils.get_db_home, db_filename)
sql_home = File.join(File.dirname(__FILE__), options["sql_src_home"])
sql_filename = Dir.glob(File.join(sql_home, '*sql'))[0]

begin
    db = SQLite3::Database.new(db_path)
    db.execute_batch(IO.read(sql_filename))

    puts "Everything is OK. Database was created at:\n#{db_path}"
rescue Exception => msg
    File.delete(db_path) if File.exists?(db_path)
    puts msg
ensure
    db.close() if db.closed? == false
end

