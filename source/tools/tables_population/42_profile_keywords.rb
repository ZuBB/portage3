#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'fileutils'
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'tools'

# hash with options
options = Hash.new.merge!(OPTIONS)
# atom prefix matcher
VERSION_RESTRICTION = Regexp.new('^[><=~]+')
# regexp to check if version is present
#VERSION_SPLITTER = Regexp.new('-|:(\\d.*)$')
# regexp to match whole version
VERSION = Regexp.new('-|:(\\d.*)$')
# regexp to check sversion
SVERSION = Regexp.new('[\*:]')
# sql
SQL_QUERY = <<SQL
INSERT INTO ebuilds2arches
(
    package_id, -- INTEGER NOT NULL
    sversion, -- VARCHAR DEFAULT NULL
    version, -- VARCHAR DEFAULT NULL
    restriction_id, --INTEGER DEFAULT NULL
    arch_id -- INTEGER NOT NULL
)
VALUES (
    ?,
    ?,
    ?,
    ?,
    (
        SELECT id
        FROM arches
        WHERE arch_name=?
    )
)
SQL

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

def parse_line(line)
    result = {}
    changed_line = line

    # take care about leading ~
    # means match any revision of the base version specified.
    # So in the above example, we would match versions
    # '1.0.2a', '1.0.2a-r1', '1.0.2a-r2', etc
    # man 5 ebuild
    changed_line.sub!('~', '') += '*' if changed_line.index('~') == 0

    # version restrictions
    match = changed_line.match(VERSION_RESTRICTION)
    unless match.nil?
        result["version_restrictions"] = match.to_s
        changed_line.sub(VERSION_RESTRICTION, '')
    end

    # deal with versions
    version_match = changed_line.match(VERSION)
    unless version_match.nil?
        # store it
        if version_match[0] == ':'
            result["version"] = version_match[1] + '*'
        else
            # if second part still have * or :
            unless version_match[1].match(SVERSION).nil?
                # its not strict version
                result["version"] = version_match[1]
            else
                # otherwise strict
                result["sversion"] = version_match[1]
            end

            # final check for complex version string
            if !result["version"].nil? && result["version"].include?(':')
                version_parts = result["version"].split(':')

                version_parts[0] += '*' unless version_parts[0].include?('*')
                result["version"] = version_parts[1]
                # TODO version that left may stil do not match requested slot
            end
        end

        changed_line.sub!(VERSION, '')
    else
        result["version"] = '*'
    end

    match = changed_line.split('/')
    result['category'] = match[0]
    result['package'] = match[1]

    return result
end

def get_arch_id(dir, database)
    sql_query = <<SQL
SELECT id
FROM arches
WHERE
    arch_name=? AND
    architecture_id=(
    ) AND
    platform_id=(
    )
SQL
    arch_name, platform, architecture = dir, nil, nil
    if arch_name == 'base/'
        architecture = platform = '*'
    else
        arch_name.sub!('base/', '')
        arch_parts = arch_name.split('/')
        architecture = arch_parts[0]
        platform = arch_parts[1] || 'linux'
    end

    database.get_first_value(sql_query, arch_name, architecture, platform)
end

def fill_table(params)
    filepath = File.join(params[:portage_home], "profiles_v2")
    FileUtils.cd(filepath)

    # walk through all use flags in that file
    Dir['**/*/'].each do |dir|
        # skip dirs that not in base
        next unless dir.include?('base')
        # skip dirs that not in base
        next if File.exist?(File.join(filepath, dir, 'deprecated'))
        # lets get filename
        filename = File.join(filepath, dir, 'package.mask')
        # skip dirs that does not have package.mask
        next unless File.exist?(filename)

        File.open(filename, "r") do |infile|
            while (line = infile.gets)
                # skip comments
                next if line.index('#') == 0
                # skip empty lines
                next if line.chomp!().empty?

                result = parse_line(line)
                result['package_id'] = get_package_id(
                    params[:database], result['category'], result['package']
                )
                result['sversion'] = params[:database].get_first_value(
                    "SELECT id from ebuilds WHERE package_id=? AND version=?",
                    params["package_id"],
                    params["sversion"]
                ) unless params["sversion"].nil?

                params[:database].execute(
                    SQL_QUERY,
                    params["package_id"],
                    params["sversion"] || nil,
                    params["version"] || nil,
                    params["version_restrictions"],
                    get_arch_id(dir, params[:database])
                )
            end
        end
    end
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)
