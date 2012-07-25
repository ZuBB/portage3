#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'ebuild'

class Script
    def pre_insert_task()
        sql_query = 'select homepage, id from ebuild_homepages;'
        @shared_data['homepages@id'] = Hash[Database.select(sql_query)]
    end

    def process(params)
        PLogger.info("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

        ebuild.ebuild_homepage.split.each { |homepage|
            Database.add_data4insert(@shared_data['homepages@id'][homepage],
                                     ebuild.ebuild_id
                                    )
        }
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => 'UPDATE ebuilds SET homepage_id=? WHERE id=?;'
})

