#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    IO.read('/etc/portage/package.use').split("\n")
end

class Script
    def pre_insert_task
        sql_query = <<-SQL
            DROP TABLE IF EXISTS tmp_etc_port_flags_pkg;

            CREATE TABLE IF NOT EXISTS tmp_etc_port_flags_pkg (
                cname VARCHAR NOT NULL,
                pname VARCHAR NOT NULL,
                CONSTRAINT idx1_unq UNIQUE (pname, cname)
            );
        SQL
        Database.execute(sql_query)
    end

    def process(line)
        return if /^\s*#/ =~ line
        Database.add_data4insert(line.split[0].split('/'))
    end

    def post_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, '/etc/portage')

        count_query = 'select count(id) from packages;'
        # http://bit.ly/tLQydk
        sql_query = <<-SQL
            INSERT INTO packages
            (name, category_id, source_id)
            SELECT tf.pname, c.id, #{source_id}
            FROM tmp_etc_port_flags_pkg tf
            JOIN categories c ON c.name=tf.cname
            WHERE NOT EXISTS (
                SELECT name FROM packages p WHERE p.name = tf.pname
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
        INSERT OR IGNORE INTO tmp_etc_port_flags_pkg (cname, pname) VALUES (?, ?);
    SQL
})

