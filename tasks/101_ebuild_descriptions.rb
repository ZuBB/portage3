#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/02/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '093_read_ebuilds_data'
    self::SQL = {
        'insert' => 'INSERT INTO ebuild_descriptions (descr) VALUES (?);'
    }

    def get_data(params)
        sql_query = 'SELECT distinct descr FROM tmp_ebuilds_data;'
        Portage3::Database.get_client.select(sql_query).flatten
    end
end

Tasks.create_task(__FILE__, klass)
