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
        sql_query = 'select description, id from ebuild_descriptions;'
        @shared_data['descriptions@id'] = Hash[Database.select(sql_query)]
    end

    def process(params)
        PLogger.info("Ebuild: #{params[3, 3].join('-')}")

        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        description_id = @shared_data['descriptions@id'][ebuild.ebuild_description]

        Database.add_data4insert(description_id, ebuild.ebuild_id)
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => 'UPDATE ebuilds SET description_id=? WHERE id=?;'
})

