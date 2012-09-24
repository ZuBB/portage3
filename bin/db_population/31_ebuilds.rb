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
    SOURCE = 'ebuilds'

    def pre_insert_task
        sql_query = 'select version, id from eapis;'
        @shared_data['eapis@id'] = Hash[Database.select(sql_query)]

        sql_query = 'select source, id from sources;'
        @shared_data['source@id'] = Hash[Database.select(sql_query)]
    end

    def process(params)
        PLogger.debug("Ebuild: #{params}")
        ebuild = Ebuild.new(params)
        eapi = ebuild.ebuild_eapi('parse')
        eapi = eapi == '0_EAPI_DEF' ? '0' : eapi

        Database.add_data4insert(
            ebuild.package_id,
            ebuild.ebuild_version,
            ebuild.repository_id,
            ebuild.ebuild_mtime,
            ebuild.ebuild_author,
            # TODO notify upstream and remove raw_eapi
            ebuild.ebuild_eapi,
            @shared_data['eapis@id'][eapi.to_i],
            ebuild.ebuild_slot,
            @shared_data['source@id'][SOURCE]
        )
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:list_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO ebuilds
        (
            package_id, version, repository_id, mtime, mauthor, raw_eapi,
            eapi_id, slot, source_id
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    SQL
})

