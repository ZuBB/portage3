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
    def get_shared_data()
        sql_query = 'select name, id from licences;'
        @shared_data['licences@id'] = Hash[Database.select(sql_query)]
    end

    def process(params)
        PLogger.info("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

        ebuild.ebuild_licences().split().each { |licence|
            Database.add_data4insert(ebuild.ebuild_id,
                                     @shared_data['licences@id'][licence]
                                    )
        }
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO ebuild_licences
        (ebuild_id, licence_id)
        VALUES (?, ?);
    SQL
})

