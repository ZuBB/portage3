#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
require_relative 'envsetup'
require 'ebuild'

def get_data(params)
    tmp_results = {}

    Ebuild.get_ebuilds.each do |row|
        package_id = row[7]
        unless tmp_results.has_key?(package_id)
            tmp_results[package_id] = {
                'category' => row[3],
                'package'  => row[4],
                'versions' => [],
                'ids'      => []
            }
        end

        tmp_results[package_id]['versions'] << row[5]
        tmp_results[package_id]['ids'] << row[6]
    end

    tmp_results.values
end

class Script
    def process(params)
        versions = params['versions']
        atom = params['category'] + '/' + params['package']
        ordered_versions = versions.sort { |a, b| Package.vercmp(a, b) }

        PLogger.info("Package #{atom}")
        PLogger.info("versions #{ordered_versions.inspect}")

        versions.each_index do |index|
            ord_num = ordered_versions.index { |version|
                version == versions[index]
            }

            if !ord_num.nil?
                Database.add_data4insert([ord_num + 1, params['ids'][index]])
            else
                PLogger.warn("Version `#{versions[index]}` - 'cache miss'")
            end
        end
    end

    def post_insert_task()
        # TASK #1: no '0' at version_order position
        # TASK #2: max(version_order) can't be bigger than ebuilds per package
        # TASK #3: no duplicates of version_order per package
        return true
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'UPDATE ebuilds SET version_order=? WHERE id=?;'
})

