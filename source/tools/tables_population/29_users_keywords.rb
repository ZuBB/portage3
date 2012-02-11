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
# sql
SQL_QUERY = <<SQL
INSERT INTO package_keywords
(package_id, version, keyword_id, arch_id, source_id)
VALUES (
    ?,
    ?,
    ?,
    ?,
    (SELECT id FROM sources WHERE source='/etc/portage/')
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

def parse_line(line, database)
    result = {}

    if line.include?(' ')
        atom = line.split()[0]
        arch = line.split()[1]
        if arch == '**'
            result["arch"] = database.execute("SELECT arch_name FROM arches;").flatten
            atom << '*' unless atom.end_with?('*')
        end
    else
        atom = line
    end

    # take care about leading ~
    # it means match any subversion of the specified base version.
    if atom.index('~') == 0
        atom.sub!(/^~/, '')

        if atom.include?(':')
            atom.sub!(":", "*:") unless atom.include?('*:')
        else
            atom << '*' unless atom.end_with?('*')
        end
    end

    # version restrictions
    unless atom.match(RESTRICTION).nil?
        result["version_restrictions"] = atom.match(RESTRICTION).to_s
        atom.sub!(RESTRICTION, '')
    end

    # deal with versions
    version_match = atom.match(ATOM_VERSION)
    version_match = version_match.to_a.compact unless version_match.nil?
    version_match = nil if version_match.size == 1 && version_match.to_s.empty?

    unless version_match.nil?
        version = version_match.last
        version << '*' if version_match.size == 2 && !atom.end_with?('*')

        if result["version_restrictions"].nil?
            result["version_restrictions"] = '='
        end

        result['version'] =  version

        atom.sub!(ATOM_VERSION, '')
    else
        result["version"] = '*'
        result["version_restrictions"] = '='
    end

    match = atom.split('/')
    result['category'] = match[0]
    result['package'] = match[1]
    if result["arch"].nil?
        result["arch"] = database.execute(
            "SELECT value FROM system_settings WHERE param='arch';"
        )
    end
    result["keyword"] = database.get_first_value(
        "SELECT value FROM system_settings WHERE param='keyword';"
    )

    return result
end

def fill_table(params)
    filename = File.join(params[:system_home], "package.keywords")
    file_content = IO.read(filename).to_a rescue []

    file_content.each { |line|
        # skip comments
        next if line.index('#') == 0
        # trim '\n'
        line.chomp!()
        # skip empty lines
        next if line.empty?()

        result = parse_line(line, params[:database])
        result['package_id'] = get_package_id(
            params[:database], result['category'], result['package']
        )

        result_set = nil

        if result["version"] == '*'
            local_query = "SELECT id FROM ebuilds WHERE package_id=?"
            result_set = params[:database].execute(local_query, result["package_id"]).flatten
        elsif result["version_restrictions"] == '=' && result["version"].end_with?('*')
            version_like = result["version"].sub('*', '')
            local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version like '#{version_like}%'"
            result_set = params[:database].execute(local_query, result["package_id"]).flatten
        else
            local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version#{result["version_restrictions"]}?"
            result_set = params[:database].execute(local_query, result["package_id"], result["version"]).flatten
        end

        if result_set.size() > 0
            result_set.each { |version|
                result['arch'].each { |arch|
                    params[:database].execute(
                        SQL_QUERY,
                        result['package_id'],
                        version,
                        result["keyword"],
                        arch
                    )
                }
            }
        else
            # means =category/atom-version that
            # already does not exist in portage
            # TODO handles this
        end
    }
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:system_home => options[:system_home]}
)
