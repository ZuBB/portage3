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
    filename = File.join(params[:portage_home], "profiles", "profiles.desc")
    profiles_file_content = IO.read(filename).to_a rescue []
    prefixes_go = false
    sql_query =<<SQL
INSERT INTO prefix_profiles
(prefix_profile, architecture_id, platform_id, status_id)
VALUES (
    ?,
    (SELECT id FROM architectures WHERE architecture=?),
    (SELECT id FROM platforms WHERE platform_name=?),
    (SELECT id FROM profile_statuses WHERE profile_status=?)
);
SQL

    # walk through all use flags in that file
    profiles_file_content.each do |line|
        prefixes_go = true if line.include?("Gentoo Prefix profiles")
        # skip clean profiles
        next if !prefixes_go
        # skip comments
        next if line.index('#') == 0
        # lets trim newlines
        line.chomp!()
        # skip empty lines
        next if line.empty?

        # lets split flag and its description
        profile_stuff = line.split()

        params[:database].execute(
            sql_query,
            profile_stuff[1],
            profile_stuff[0].split('-')[0],
            profile_stuff[0].split('-')[1],
            profile_stuff[2]
        )
    end
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)

