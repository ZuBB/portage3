#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'ebuild'

class Script
    def process(params)
        PLogger.info("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

        ebuild.ebuild_use_flags.split.each do |flag|
            # app-doc/pms section 8.2
            flag_state = flag[0].chr == '+' ? 1 : 0
            flag_name = flag.sub(/^(-|\+)/, '')

            Database.add_data4insert(
                ebuild.package_id,
                ebuild.ebuild_id,
                flag_name,
                flag_state,
                1 # TODO source_id
            )
        end
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO use_flags2ebuilds
        (package_id, ebuild_id, use_flag_id, flag_state, source_id)
        VALUES (?, ?, (SELECT id FROM use_flags WHERE flag_name=?), ?, ?);
    SQL
})

