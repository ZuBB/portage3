#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '071_read_maintainers_data'
    self::SQL = {
        'insert' => 'INSERT INTO roles (role) VALUES (?);'
    }

    def get_data(params)
        #['gentoo maintainer', 'upstream maintainer', 'proxying maintainer']
        sql_query = 'select distinct role from tmp_package_maintainers;';
        @database.select(sql_query).flatten
    end

    def process_item(params)
        unless (str = params.strip).empty?
            send_data4insert({'data' => [str]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

