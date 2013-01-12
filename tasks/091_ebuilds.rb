#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
#equire 'eapi'
require 'source'
require 'ebuild'

klass = Class.new(Tasks::Runner) do
    self::PRI_INDEX = 2
    self::DEPENDS = '041_packages' # ;009_eapis
    self::THREADS = 4
    self::SOURCE = 'ebuilds'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds
            (package_id, version, repository_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Ebuild.list_ebuilds(params)
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
       #request_data('eapi@id', Eapi::SQL['@'])
    end

    def process_item(params)
        @logger.debug("Ebuild: #{params}")
        ebuild = Ebuild.new(params)

        send_data4insert({'data' => [
            ebuild.package_id,
            ebuild.ebuild_version,
            ebuild.repository_id,
            shared_data('source@id', self.class::SOURCE)
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

