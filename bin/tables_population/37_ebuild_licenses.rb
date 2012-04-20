#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'ebuild'

script = Script.new({
    "script" => __FILE__,
    "table" => "package_licenses",
    "helper_query1" => <<SQL
INSERT INTO licenses2ebuilds
(license_id, package_id, ebuild_id)
VALUES (?, ?, ?)
SQL
})

def parse_ebuild(params)
    PLogger.info("Ebuild: #{params["filename"]}")
    Ebuild.new(Utils.create_ebuild_params(params))
end

def store_ebuild_licenses(ebuild, tablename)
    license_ids = []
    ebuild.license().split(' ').each { |license|
        license_ids << Database.insert({
            "table" => tablename,
            "command" => "INSERT OR REPLACE",
            "data" => {"license" => license}
        })
    }

    return license_ids
end

def link_licenses2ebuild(ebuild, license_ids, sql_query)
    license_ids.each { |license_id|
        Database.insert({
            "sql_query" => sql_query,
            "values" => [license_id, ebuild.package_id(), ebuild.ebuild_id()]
        })
    }
end

def category_block(params)
    Utils.walk_through_packages({"block2" => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    Dir.glob(File.join(params["item_path"], '*.ebuild')).each do |ebuild|
        ebuild = parse_ebuild({"filename" => ebuild}.merge!(params))
        license_ids = store_ebuild_licenses(ebuild, params["table"])
        link_licenses2ebuild(ebuild, license_ids, params["helper_query1"])
    end
end

def fill_table(params)
    Utils.walk_through_categories(
        {"block1" => method(:category_block)}.merge!(params)
    )
end

script.fill_table_X(method(:fill_table))

