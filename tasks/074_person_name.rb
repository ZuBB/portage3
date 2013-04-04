#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
require 'package'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '073_person_email'
    self::SQL = {
        'insert' => 'update persons set name = ? where id = ?;',
        'select' => <<-SQL
            select name, count(name) as c
            from tmp_package_maintainers
            where LOWER(email) = ?/*like '%?%'*/ and name != ''
            group by name
            order by c desc
            limit 1;
        SQL
    }

    def get_data(params)
        @database.select('select email, id from persons;')
    end

    def process_item(params)
        res = @database.select(self.class::SQL['select'], params[0])
        unless res.empty?
            send_data4insert({'data' => [res[0][0], params[1]]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

