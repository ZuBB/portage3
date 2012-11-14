#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/02/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '095_ebuild_descriptions'
    self::SQL = {
        'insert' => 'INSERT INTO ebuild_descriptions (descr) VALUES (?);'
    }

    def get_data(params)
        sql_query = 'SELECT distinct descr FROM tmp_ebuild_descriptions;'
        Database.select(sql_query).flatten
    end
end

Tasks.create_task(__FILE__, klass)

