#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
$:.push File.expand_path(File.join(*(lib_path_items + ['portage'])))
require 'script'
require 'ebuild'

def get_data(params)
    # query
    sql_query = <<-SQL
        SELECT c.category_name, p.package_name, p.id
        FROM packages p
        INNER JOIN categories c on p.category_id=c.id
        ORDER BY p.id ASC
    SQL

    # lets get all packages
    results = Database.select(sql_query)

    # query
    sql_query = <<-SQL
        SELECT package_id, id, version
        FROM ebuilds
        ORDER BY package_id ASC
    SQL

    # lets get all ebuild versions
    tmp_results = {}
    Database.select(sql_query).each do |row|
        package_id = row[0]
        unless tmp_results.has_key?(package_id)
            tmp_results[package_id] = [[], []]
        end

        tmp_results[package_id][0] << row[1]
        tmp_results[package_id][1] << row[2]
    end

    results.map! do |row|
        package_id = row.pop()
        if tmp_results.has_key?(package_id)
            row << tmp_results[package_id][0]
            row << tmp_results[package_id][1]
        else
            row = nil
        end

        row
    end

    return results.compact()
end

def process(params)
    # get atom name
    atom = params['value'][0] + '/' + params['value'][1]
    PLogger.debug("Package #{atom}")

    # get all versions of the package, sorted by versions
    versions = PackageModule.get_package_versions(atom)

    # lets get them
    params['value'][2].each_index do |data_index|
        index = versions.index { |version|
            version == params['value'][3][data_index]
        }

        if !index.nil?
            Database.add_data4insert([index + 1, params['value'][2][data_index]])
        else
            PLogger.warn("Version `#{params['value'][3][data_index]}` - 'cache miss'")
            PLogger.info("versions #{versions.join(', ')}")
        end
    end
end

script = Script.new({
    "script" => __FILE__,
    "thread_code" => method(:process),
    "data_source" => method(:get_data),
    'sql_query' => 'UPDATE ebuilds SET version_order=? WHERE id=?;',
    "max_threads" => 4
})

