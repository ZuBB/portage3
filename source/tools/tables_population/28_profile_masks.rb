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
RESTRICTION = Regexp.new("^[^\\w]+")
# regexp to match version
VERSION = Regexp.new('((?:-)(\\d[^:]*))?(?:(?::)(\\d.*))?$')
# sql
SQL_QUERY = <<SQL
INSERT INTO packages2masks
(package_id, version, arch_id, mask_state_id, source_id)
VALUES (
    ?,
    ?,
    (SELECT id FROM arches WHERE arch_name=?),
    (SELECT id FROM mask_states WHERE mask_state=?),
    (SELECT id FROM sources WHERE source=?)
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

    # take care about leading '-'
    # it means this atom/package should treated as unmasked
    result["mask_state"] = line.index('-') == 0 ? 'unmasked' : 'masked'

    # take care about leading ~
    # it means match any subrevision of the specified base version.
    if line.index('~') == 0
        line.sub!(/^~/, '')

        if line.include?(':')
            line.sub!(":", "*:") unless line.include?('*:')
        else
            line << '*' unless line.end_with?('*')
        end
    end

    # version restrictions
    unless line.match(RESTRICTION).nil?
        result["version_restrictions"] = line.match(RESTRICTION).to_s
        line.sub!(RESTRICTION, '')
    end

    # deal with versions
    version_match = line.match(VERSION)
    version_match = version_match.to_a.compact unless version_match.nil?
    version_match = nil if version_match.size == 1 && version_match.to_s.empty?

    unless version_match.nil?
        result["version"] = version_match.last
        result["version"] << '*' if version_match.size == 2

        if result["version_restrictions"].nil?
            result["version_restrictions"] = '='
        end

        line.sub!(VERSION, '')
    else
        result["version"] = '*'
        result["version_restrictions"] = '='
    end

    match = line.split('/')
    result['category'] = match[0]
    result['package'] = match[1]

    return result
end

def get_source_id(database, dir)
    database.get_first_value("SELECT id FROM sources WHERE source=?", dir)
end

def fill_table(params)
    filepath = File.join(params[:portage_home], "profiles_v2")
    FileUtils.cd(filepath)

    # walk through all use flags in that file
    Dir['**/*/'].each do |dir|
        # skip dirs that not in base
        next unless dir.index('base') == 0
        # skip dirs that has 'deprecated' file in it
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
                params[:database].execute(
                    SQL_QUERY,
                    get_package_id(
                        params[:database], result['category'], result['package']
                    ),
                    result["version"],
                    result["mask_state"],
                    result["version_restrictions"],
                    get_source_id(params[:database], dir)
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
