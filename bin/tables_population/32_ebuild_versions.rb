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
    results = []
    # query
    sql_query = <<-SQL
        SELECT c.category_name, p.package_name, p.id
        FROM packages p
        INNER JOIN categories c on p.category_id=c.id
    SQL

    # lets walk through all packages
    Database.select(sql_query).each { |row|
        results << {
            "category" => row[0],
            "package" => row[1],
            "package_id" => row[2],
        }
    }

    return results
end

def process(params)
    # query for getting all versions of current package
    sql_query1 = 'SELECT id,version FROM ebuilds WHERE package_id=?'
    # query for updating
    sql_query2 = 'UPDATE ebuilds SET version_order=? WHERE id=?'
    # get atom name
    atom = params['value']['category'] + '/' + params['value']['package']
    PLogger.info("Package #{atom}")

    # get all versions of the package, sorted by versions
    versions = PackageModule.get_package_versions(atom)

    # lets get them
    Database.select(sql_query1, params['value']['package_id']).each do |row|
        index = versions.index { |version| version == row[1] }

        if !index.nil?
            # TODO: replace with bunch update
            Database.execute(sql_query2, [index + 1, row[0]])
        else
            PLogger.warn("Version #{row[1]} - 'cache miss'")
            PLogger.info("versions #{versions.join(', ')}")
        end
    end
end

script = Script.new({
    "table" => "ebuilds",
    "script" => __FILE__,
    "thread_code" => method(:process),
    "data_source" => method(:get_data),
    "max_threads" => 4
})

