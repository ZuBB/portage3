#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'ebuild'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '091_ebuilds'
    self::THREADS = 4
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_ebuild_homepages
            (homepage, ebuild_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Ebuild.get_ebuilds(params)
    end

    def process_item(params)
        @logger.debug("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

        ebuild.ebuild_homepage.split.each { |homepage|
            send_data4insert({'data' => [homepage, ebuild.ebuild_id]})
        }
    end
end

Tasks.create_task(__FILE__, klass)

