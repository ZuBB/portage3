#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'ebuild'

class Script
    def pre_insert_task()
        sql_query = <<-SQL
            CREATE TABLE IF NOT EXISTS tmp_ebuild_homepages (
                id INTEGER,
                homepage VARCHAR NOT NULL,
                ebuild_id INTEGER NOT NULL,
                PRIMARY KEY (id)
            );

            CREATE INDEX ted on tmp_ebuild_homepages (description);
        SQL
        Database.execute(sql_query)
    end

    def process(params)
        PLogger.info("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

        ebuild.ebuild_homepage.split.each { |homepage|
            Database.add_data4insert(homepage)
        }
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO tmp_ebuild_homepages
        (homepage, ebuild_id)
        VALUES (?, ?);
    SQL
})

