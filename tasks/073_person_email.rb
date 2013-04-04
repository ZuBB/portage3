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
        'insert' => 'INSERT INTO persons (email) VALUES (?);'
    }

    def get_data(params)
        sql_query = 'select distinct email from tmp_package_maintainers;';
        @database.select(sql_query).flatten
        .map! { |email| email.downcase }
        .map! { |email| email.sub('>', '') }
        .uniq
    end
end

Tasks.create_task(__FILE__, klass)

