#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'ebuild'

class Script
    def pre_insert_task
        sql_query = <<-SQL
            DROP TABLE IF EXISTS tmp_ebuild_descriptions;

            CREATE TABLE IF NOT EXISTS tmp_ebuild_descriptions (
                id INTEGER,
                description VARCHAR NOT NULL,
                ebuild_id INTEGER NOT NULL,
                PRIMARY KEY (id)
            );

            CREATE INDEX ted on tmp_ebuild_descriptions (description);
        SQL
        Database.execute(sql_query)
    end

    def process(params)
        PLogger.debug("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

        Database.add_data4insert(ebuild.ebuild_description, ebuild.ebuild_id)
    end

    def post_insert_task
        count_query = 'select count(id) from ebuild_descriptions;'
        sql_query = <<-SQL
            INSERT INTO ebuild_descriptions
            (descr)
            SELECT distinct description
            FROM tmp_ebuild_descriptions;
        SQL

        tb = Database.get_1value(count_query)
        Database.execute(sql_query)
        ta = Database.get_1value(count_query)

        "#{ta - tb} successful inserts has beed done"
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO tmp_ebuild_descriptions
        (description, ebuild_id)
        VALUES (?, ?);
    SQL
})

