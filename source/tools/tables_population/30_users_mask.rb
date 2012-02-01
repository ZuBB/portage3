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
# atom prefix matcher
RESTRICTION = Regexp.new("^[^\\w]+")
# regexp to match version
ATOM_SUFFIX = Regexp.new('((?:-)(\\d[^:]*))?(?:(?::)(\\d.*))?$')
# sql
SQL_QUERY = <<SQL
INSERT INTO packages2masks
(package_id, version, mask_state_id, restriction_id, source_id)
VALUES (
    ?,
    ?,
    (SELECT id FROM mask_states WHERE mask_state=?),
    (SELECT id FROM restriction_types WHERE restriction=?),
    ?
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
    version_match = line.match(ATOM_SUFFIX)
    version_match = version_match.to_a.compact unless version_match.nil?
    version_match = nil if version_match.size == 1 && version_match.to_s.empty?

    unless version_match.nil?
        result["version"] = version_match.last
        result["version"] << '*' if version_match.size == 2

        if result["version_restrictions"].nil?
            result["version_restrictions"] = '='
        end

        line.sub!(ATOM_SUFFIX, '')
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

def parse_file(params, file_content, mask_state)
    file_content.each { |line|
        # skip comments
        next if line.index('#') == 0
        # trim '\n'
        line.chomp!()
        # skip empty lines
        next if line.empty?()

        result = parse_line(line)
        params[:database].execute(
            SQL_QUERY,
            get_package_id(
                params[:database], result['category'], result['package']
            ),
            result["version"],
            mask_state,
            result["version_restrictions"],
            get_source_id(params[:database], '/etc/portage/')
        )
    }
end

def fill_table(params)
    filename = File.join(params[:system_home], "package.mask")
    parse_file(params, (IO.read(filename).to_a rescue []), 'masked')

    filename = File.join(params[:system_home], "package.unmask")
    parse_file(params, (IO.read(filename).to_a rescue []), 'unmasked')
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:system_home => options[:system_home]}
)
