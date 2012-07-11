#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
$:.push File.expand_path(File.join(*(lib_path_items + ['portage'])))
require 'script'
require 'ebuild'

def process(params)
    PLogger.info("Ebuild: #{params["value"]}")
    ebuild = Ebuild.new(params)

    Database.add_data4insert([
        ebuild.package_id,
        ebuild.ebuild_version,
        ebuild.repository_id_by_fs,
        #"mtime" => ebuild.ebuild_mtime,
        #"mauthor" => ebuild.ebuild_author,
        #"eapi_id" => ebuild.ebuild_eapi_id,
        #"slot" => ebuild.ebuild_slot
    ])
end

script = Script.new({
    "script" => __FILE__,
    "thread_code" => method(:process),
    "data_source" => Ebuild.method(:get_ebuilds),
    'sql_query' => 'INSERT INTO ebuilds (package_id, version, repository_id) VALUES (?, ?, ?);',
})

