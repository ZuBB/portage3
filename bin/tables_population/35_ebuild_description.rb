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
    "table" => "package_descriptions",
    "helper_query1" => <<SQL
INSERT INTO descriptions2ebuilds
(description_id, package_id, ebuild_id)
VALUES (?, ?, ?)
SQL
})

def parse_ebuild(params)
    PLogger.info("Ebuild: #{params["filename"]}")
    Ebuild.new(Utils.create_ebuild_params(params))
end

def store_ebuild_description(ebuild, tablename)
    Database.insert({
        "table" => tablename,
        "command" => "INSERT OR REPLACE",
        "data" => {"description" => ebuild.description()}
    })
end

def link_description2ebuild(ebuild, description_id, sql_query)
    Database.insert({
        "sql_query" => sql_query,
        "values" => [description_id, ebuild.package_id(), ebuild.ebuild_id()]
    })
end

def category_block(params)
    Utils.walk_through_packages({"block2" => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    Dir.glob(File.join(params["item_path"], '*.ebuild')).each do |ebuild|
        ebuild = parse_ebuild({"filename" => ebuild}.merge!(params))
        description_id = store_ebuild_description(ebuild, params["table"])
        link_description2ebuild(ebuild, description_id, params["helper_query1"])
    end
end

def fill_table(params)
    Utils.walk_through_categories(
        {"block1" => method(:category_block)}.merge!(params)
    )
end

script.fill_table_X(method(:fill_table))

