#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::PRI_INDEX = 1.5
    self::DEPENDS = '091_ebuilds' # ;009_eapis
    self::THREADS = 4
    self::SOURCE = 'ebuilds'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_ebuilds_data
            (ebuild_id, mtime, mauthor, keywords, use_flags, descr, homepages, slot)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Ebuild.get_ebuilds(params)
    end

    def get_shared_data
       #Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
       #Tasks::Scheduler.set_shared_data('eapi@id', Eapi::SQL['@'])
    end

    def process_item(params)
        @logger.debug("Ebuild: #{params}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
       #eapi = ebuild.ebuild_eapi('parse')
       #eapi = eapi == '0_EAPI_DEF' ? '0' : eapi

        send_data4insert({'data' => [
            ebuild.ebuild_id,
            ebuild.ebuild_mtime,
            ebuild.ebuild_author,
            ebuild.ebuild_keywords,
            ebuild.ebuild_use_flags,
            ebuild.ebuild_description,
            ebuild.ebuild_homepage,
            # TODO notify upstream and remove raw_eapi
            #ebuild.ebuild_eapi,
            #shared_data('eapi@id', eapi.to_i),
            ebuild.ebuild_slot
        ]})
    end
end

Tasks.create_task(__FILE__, klass)
