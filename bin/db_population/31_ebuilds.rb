#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'ebuild'

class Script
    def process(params)
        PLogger.info("Ebuild: #{params}")
        ebuild = Ebuild.new(params)

        Database.add_data4insert(ebuild.package_id,
                                 ebuild.ebuild_version,
                                 ebuild.repository_id
                                 #ebuild.ebuild_mtime,
                                 #ebuild.ebuild_author,
                                 #ebuild.ebuild_eapi_id,
                                 #ebuild.ebuild_slot
        )
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:list_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO ebuilds
        (package_id, version, repository_id)
        VALUES (?, ?, ?);
    SQL
})

