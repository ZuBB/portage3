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
    def pre_insert_task
        sql_query = <<-SQL
            DROP TABLE IF EXISTS tmp_etc_port_flags;

            CREATE TABLE IF NOT EXISTS tmp_etc_port_flags (
                name VARCHAR NOT NULL,
				package_id INTEGER
            );
        SQL
        Database.execute(sql_query)

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
        words = line.split
		atom = words.delete_at(0)
        words.each { |flag|
            flag_name = UseFlag.get_flag(flag)
            next if flag_name == '*'
			Database.add_data4insert(flag_name, @shared_data['atom@id'][atom])
        }
    end

    def post_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, '/etc/portage')
        type_id = Database.get_1value(UseFlag::SQL['type'], 'unknown')

        count_query = 'select count(id) from flags;'
        # http://bit.ly/tLQydk
        sql_query = <<-SQL
            INSERT INTO flags
            (name, type_id, source_id)
            SELECT tf.name, #{type_id}, #{source_id}
            FROM tmp_etc_port_flags tf
            WHERE NOT EXISTS (
                SELECT name
				FROM flags f
				WHERE
					(f.name = tf.name AND f.package_id IS NULL) OR 
					(f.name = tf.name AND tf.package_id = f.package_id)

            );
        SQL

        tb = Database.get_1value(count_query)
        Database.execute(sql_query)
        ta = Database.get_1value(count_query)

        "#{ta - tb} successful inserts has beed done"
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT OR IGNORE INTO tmp_etc_port_flags (name, package_id) VALUES (?, ?);
    SQL
})

