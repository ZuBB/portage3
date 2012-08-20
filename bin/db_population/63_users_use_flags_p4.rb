#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'

def get_data(params)
    IO.read('/etc/portage/package.use').split("\n")
end

class Script
    SOURCE = '/etc/portage'

    def pre_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, SOURCE)
        @shared_data['source@id'] = { SOURCE => source_id }

        sql_query = 'select state, id from flag_states;'
        @shared_data['state@id'] = Hash[Database.select(sql_query)]

        @shared_data['atom@id'] = {}
        sql_query = <<-SQL
            select c.name, p.name, p.id
            from packages p
            join categories c on p.category_id=c.id;
        SQL
        Database.select(sql_query).each do |row|
            key = row[0] + '/' + row[1]
            @shared_data['atom@id'][key] = row[2]
        end
    end

    def process(line)
        return if /^\s*#/ =~ line
        line.sub!(/#.*$/, '')
        flags = line.split
        params_c = [@shared_data['source@id'][SOURCE]]
        params_c << @shared_data['atom@id'][flags.delete_at(0)]
        if line.include?('*')
            flags = UseFlag.expand_asterix_flag(line, params_c.last).split
        end
        flags.each do |flag|
            params = params_c.dup
            params << UseFlag.get_flag(flag)
            params << @shared_data['state@id'][UseFlag.get_flag_state(flag)]
            Database.add_data4insert(params)
        end
    end

    def post_insert_task
        sql_query = <<-SQL
            DROP TABLE IF EXISTS tmp_etc_port_flags;
            DROP TABLE IF EXISTS tmp_etc_port_flags_cat;
            DROP TABLE IF EXISTS tmp_etc_port_flags_pkg;
        SQL

        Database.execute(sql_query)
    end
end

script = Script.new({
    'max_threads' => 1,
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO flags_states
        (source_id, package_id, flag_id, state_id)
        VALUES (
            ?,
            ?,
            (SELECT id FROM flags WHERE name=? ORDER BY type_id ASC LIMIT 1),
            ?
        );
    SQL
})

