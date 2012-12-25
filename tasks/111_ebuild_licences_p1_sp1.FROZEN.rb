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
require 'license'

class Script
    def pre_insert_task
        sql_query = <<-SQL
            DROP TABLE IF EXISTS tmp_ebuild_licenses_p1;
            CREATE TABLE tmp_ebuild_licenses_p1 (
                id INTEGER,
                ebuild_id INTEGER,
                --license_spec_id INTEGER,
                license VARCHAR,
                PRIMARY KEY (id)
            );
        SQL
        Database.execute(sql_query)
    end

    def process(params)
        @logger.debug("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        licenses = License.get_0dep_licenses(ebuild.ebuild_licences)

        licenses.split.each { |license|
            Database.add_data4insert(ebuild.ebuild_id, license)
        }
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO tmp_ebuild_licenses_p1
        (ebuild_id, license)
        VALUES (?, ?);
    SQL
})
