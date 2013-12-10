#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '631_package_flagstates'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO flags
            (name, type_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = UseFlag::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_dropped_flags')
        @database.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)
