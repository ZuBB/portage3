#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '098_ebuild_homepages'
    self::SQL = {
        'insert' => 'INSERT INTO ebuild_homepages (homepage) VALUES (?);'
    }

    def get_data(params)
        sql_query = 'SELECT distinct homepage FROM tmp_ebuild_homepages;'
        Database.select(sql_query).flatten
    end
end

Tasks.create_task(__FILE__, klass)

