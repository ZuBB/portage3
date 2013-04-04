#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '073_person_email'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO packages2maintainers
            (person_id, package_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        @database.select(
            <<-SQL
                select distinct p.id, t.package_id
                from tmp_package_maintainers t
                join persons p on p.email = t.email;
            SQL
        )
    end
end

Tasks.create_task(__FILE__, klass)

