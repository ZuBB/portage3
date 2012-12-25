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
    self::DEPENDS = '093_read_ebuilds_data'
    self::THREADS = 4
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_ebuild_homepages
            (homepage, ebuild_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Ebuild.get_ebuilds_data('homepages')
    end

    def process_item(params)
        @logger.debug("Ebuild: #{params[3, 3].join('-')}")

        params.last.split.each { |homepage|
            send_data4insert({'data' => [homepage, params[6]]})
        }
    end
end

Tasks.create_task(__FILE__, klass)
