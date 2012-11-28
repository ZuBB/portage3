#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'eapi'
require 'ebuild'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '021_repositories;041_packages' # ;009_eapis
    self::THREADS = 4
    self::SOURCE = 'ebuilds'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds
            (
                package_id, version, repository_id, mtime, mauthor, /*raw_eapi,
                eapi_id,*/ slot, source_id
            )
            VALUES (?, ?, ?, ?, ?, ?, ?/*, ?, ?*/);
        SQL
    }

    def get_data(params)
        Ebuild.list_ebuilds(params)
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
        Tasks::Scheduler.set_shared_data('eapi@id', Eapi::SQL['@'])
    end

    def process_item(params)
        PLogger.debug(@id, "Ebuild: #{params}")
        ebuild = Ebuild.new(params)
        eapi = ebuild.ebuild_eapi('parse')
        eapi = eapi == '0_EAPI_DEF' ? '0' : eapi

        send_data4insert({'data' => [
            ebuild.package_id,
            ebuild.ebuild_version,
            ebuild.repository_id,
            ebuild.ebuild_mtime,
            ebuild.ebuild_author,
            # TODO notify upstream and remove raw_eapi
            #ebuild.ebuild_eapi,
            #shared_data('eapi@id', eapi.to_i),
            ebuild.ebuild_slot,
            shared_data('source@id', self.class::SOURCE)
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

