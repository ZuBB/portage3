#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'package'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '041_packages;153_profile_masks'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO packages
            (name, category_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = Package::SQL['ghost'].dup
        sql_query.sub!('TMP_TABLE', 'tmp_profile_mask_packages')
        Portage3::Database.get_client.select(sql_query)
    end
end

Tasks.create_task(__FILE__, klass)

