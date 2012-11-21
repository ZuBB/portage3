#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'repository'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '155_profile_masks'
    self::SOURCE = 'profiles'
    self::REPO = 'unknown'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds
            (package_id, version, repository_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        sql_query = <<-SQL
            SELECT distinct package_id, version
            FROM tmp_profile_mask_ebuilds te
            WHERE NOT EXISTS (
                SELECT version
                FROM ebuilds e
                WHERE
                    e.version = te.version AND
                    e.package_id = te.package_id
            );
        SQL
        Database.select(sql_query)
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
        Tasks::Scheduler.set_shared_data('repository@id', Repository::SQL['@'])
    end

    def process_item(params)
        params << shared_data('repository@id', self.class::REPO)
        params << shared_data('source@id', self.class::SOURCE)
        send_data4insert({'data' => params})
    end
end

Tasks.create_task(__FILE__, klass)
