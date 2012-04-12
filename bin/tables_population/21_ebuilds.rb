#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'ebuild'

script = Script.new({
    "table" => "ebuilds",
    "script" => __FILE__
})

def parse_ebuild(params)
    PLogger.debug("Ebuild: #{params["filename"]}")

    ebuild = Ebuild.new(Utils.create_ebuild_params(params))
    Database.insert({
        "table" => params["table"],
        "data" => {
            "package_id" => ebuild.package_id,
            "version" => ebuild.version,
            "version_order" => 1,
            "mtime" => ebuild.mtime,
            "mauthor" => ebuild.author,
            "eapi_id" => ebuild.eapi_id(),
            "slot" => ebuild.slot,
            "license" => ebuild.license
        }
    })

    # TODO store_real_eapi(ebuild_obj)
end

def category_block(params)
    Utils.walk_through_packages({"block2" => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    Dir.glob(File.join(params["item_path"], '*.ebuild')).each do |ebuild|
        parse_ebuild({"filename" => ebuild}.merge!(params))
    end
end

def fill_table(params)
    Utils.walk_through_categories(
        {"block1" => method("category_block")}.merge!(params)
    )
end

script.fill_table_X(method(:fill_table))

