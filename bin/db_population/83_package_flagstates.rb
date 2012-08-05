#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'

def get_data(params)
    sql_query = <<-SQL
        SELECT ip.id, c.category_name, p.package_name, e.version
        FROM installed_packages ip
        JOIN ebuilds e ON e.id = ip.ebuild_id
        JOIN packages p ON e.package_id = p.id
        JOIN categories c ON p.category_id = c.id;
    SQL

    Database.select(sql_query)
end

class Script
    def pre_insert_task
        sql_query = 'select state, id from flag_states;'
        @shared_data['state@id'] = Hash[Database.select(sql_query)]
    end

    def process(param)
        path = '/var/db/pkg'
        dir = File.join(path, param[1], param[2] + '-' + param[3])
        iebuild_id = param[0]
        useflags = []

        ['IUSE', 'USE'].each do |file|
            next unless File.exist?(use_file = File.join(dir, file))
            useflags += IO.read(use_file).split
        end

        useflags.uniq.each do |flag|
            flag_name = UseFlag.get_flag(flag)
            flag_state = UseFlag.get_flag_state(flag)
            Database.add_data4insert(iebuild_id, flag_name, flag_state)
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO package_flagstates
        (iebuild_id, flag_id, state_id)
        VALUES (
            ?,
            (
                SELECT id
                FROM flags
                WHERE name=?
                ORDER BY type_id ASC
                LIMIT 1
            ),
            ?
        );
    SQL
})

