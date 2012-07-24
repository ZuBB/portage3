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
    def process(params)
        PLogger.info("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

        Database.add_data4insert(ebuild.ebuild_description, ebuild.ebuild_id)
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    "sql_query" => <<-SQL
        INSERT INTO tmp_ebuild_descriptions
        (description, ebuild_id)
        VALUES (?, ?);
    SQL
})

