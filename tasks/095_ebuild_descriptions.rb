#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'ebuild'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '091_ebuilds'
    self::THREADS = 4
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_ebuild_descriptions
            (descr, ebuild_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Ebuild.get_ebuilds(params)
    end

    def process_item(params)
        PLogger.debug(@id, "Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        send_data4insert({'data' => [
             ebuild.ebuild_description,
             ebuild.ebuild_id
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

