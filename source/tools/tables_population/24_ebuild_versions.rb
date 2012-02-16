#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'tools'
require 'time'

# hash with options
options = Hash.new.merge!(OPTIONS)
# hash with options
SQL_QUERY = <<SQL
INSERT INTO ebuilds
(package_id, version, mtime, mauthor, eapi_id, slot, license)
VALUES (?, ?, ?, ?, ?, ?, ?);
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

def compare_package_versions(ebuild_a, ebuild_b)
    a_parts = ebuild_a.split(/[\.\-_]/)
    b_parts = ebuild_b.split(/[\.\-_]/)
    comparison_result = nil

    a_parts.each_index { |index|
        a_part_raw = a_parts[index] rescue ''
        b_part_raw = b_parts[index] rescue ''

        if a_part_raw && b_part_raw.nil?
            comparison_result = 1
            break
        end

        a_part = a_part_raw.to_i
        b_part = b_part_raw.to_i

        is_a_num = a_part.to_s == a_part_raw
        is_b_num = b_part.to_s == b_part_raw

        if a_part_raw == b_part_raw
            next
        elsif is_a_num == is_b_num && is_b_num == true
            comparison_result = a_part > b_part ? 1 : -1
        elsif is_a_num == is_b_num && is_b_num == false && a_part_raw.size == b_part_raw.size
            comparison_result = a_part_raw > b_part_raw ? 1 : -1
        else
            a_sub_part = a_part_raw.scan(/\d+|[a-z]+/)
            b_sub_part = b_part_raw.scan(/\d+|[a-z]+/)

            if a_sub_part[0] == b_sub_part[0]
                if a_sub_part[1] && b_sub_part[1].nil?
                    comparison_result = 1
                elsif b_sub_part[1] && a_sub_part[1].nil?
                    comparison_result = -1
                elsif a_sub_part[1].to_i > b_sub_part[1].to_i
                    comparison_result = 1
                else
                    comparison_result = -1
                end
            else
                comparison_result = a_sub_part[0] > b_sub_part[0] ? 1 : -1
            end
        end

        break unless comparison_result.nil?
    }

    if comparison_result.nil?
        comparison_result = a_parts.size > b_parts.size ? 1 : -1
    end

    return comparison_result
end

def fill_table(params)
    # lets walk through all packages
    params[:database].execute("SELECT id from packages") do |row|
        # query for getting all versions of current package
        sql_query1 = "SELECT id,version FROM ebuilds WHERE package_id=?"
        # query for getting all versions of current package
        sql_query2 = "UPDATE ebuilds SET version_order=? WHERE id=?"
        # empty array for versions only
        versions = []
        # lets get them
        rows = params[:database].execute(sql_query1, row[0])
        # get them..
        rows.each { |row| versions << row[1] }
        # ..and sort
        sorted_versions = versions.sort { |item_1, item_2|
            compare_package_versions(item_1, item_2)
        }
        # and store sort order
        sorted_versions.each_index do |ii|
            params[:database].execute(
                sql_query2,
                ii + 1,
                rows[versions.index(sorted_versions[ii])][0]
            )
        end
    end
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)
