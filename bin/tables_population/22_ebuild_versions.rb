#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "script" => __FILE__,
    # query for getting all versions of current package
    "sql_query" => "UPDATE ebuilds SET version_order=? WHERE id=?",
    # query for getting all packages
    "helper_query1" => "SELECT id from packages",
    # query for getting all versions of current package
    "helper_query2" => "SELECT id,version FROM ebuilds WHERE package_id=?"
})

def compare_package_versions(ebuild_a, ebuild_b)
    p '='*10 if @debug
    a_parts = ebuild_a.split(/[\.\-_]/)
    b_parts = ebuild_b.split(/[\.\-_]/)
    comparison_result = nil

    a_parts.each_index { |index|
        a_part_raw = a_parts[index] rescue ''
        b_part_raw = b_parts[index] rescue ''
        p '-'*10 if @debug
        p a_part_raw if @debug
        p b_part_raw if @debug

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
            p 'case 1' if @debug
            comparison_result = a_part > b_part ? 1 : -1
        elsif is_a_num == is_b_num && is_b_num == false && a_part_raw.size == b_part_raw.size
            p 'case 2' if @debug
            comparison_result = a_part_raw > b_part_raw ? 1 : -1
        else
            a_sub_part = a_part_raw.scan(/\d+|[a-z]+/)
            b_sub_part = b_part_raw.scan(/\d+|[a-z]+/)
            p 'case 3' if @debug
            #p 'a_sub_part'
            #p a_sub_part
            #p 'b_sub_part'
            #p b_sub_part

            if a_sub_part[0] == b_sub_part[0]
                if a_sub_part[1] && b_sub_part[1].nil?
                    comparison_result = 1
                elsif b_sub_part[1] && a_sub_part[1].nil?
                    comparison_result = -1
                elsif a_sub_part[1].to_i > b_sub_part[1].to_i
                    comparison_result = 1
                    #p '1st is bigger'
                else
                    comparison_result = -1
                    #p '2nd is bigger'
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
    Database.db().execute(params["helper_query1"]) do |row|
        # empty array for versions only
        versions = []
        # lets get them
        rows = Database.db().execute(params["helper_query2"], [row[0]])
        # get them..
        rows.each { |row| versions << row[1] }
        # ..and sort
        sorted_versions = versions.sort { |item_1, item_2|
            compare_package_versions(item_1, item_2)
        }
        # and store sort order
        sorted_versions.each_index do |ii|
            Database.insert({
                "sql_query" => params["sql_query"],
                "values" => [
                    ii + 1, rows[versions.index(sorted_versions[ii])][0]
            ]
            })
        end
    end
end

script.fill_table_X(method(:fill_table))

