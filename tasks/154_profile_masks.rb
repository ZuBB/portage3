#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '153_profile_masks'
    self::SOURCE = 'profiles'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO packages
            (name, category_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = <<-SQL
            SELECT distinct package, category_id
            FROM tmp_profile_mask_packages tp
            WHERE NOT EXISTS (
                SELECT name FROM packages p WHERE p.name = tp.package
            );
        SQL
        Database.select(sql_query)
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
    end

    def process_item(params)
        params << shared_data('source@id', self.class::SOURCE)
        send_data4insert({'data' => params})
    end
end

Tasks.create_task(__FILE__, klass)

