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
require 'parser'

def get_data(params)
    file_content = IO.read('/etc/make.conf').split("\n")
    Parser.get_multi_line_ini_value(file_content, 'USE').split
end

class Script
    def pre_insert_task
        sql_query = <<-SQL
            DROP TABLE IF EXISTS tmp_make_conf_flags;

            CREATE TABLE IF NOT EXISTS tmp_make_conf_flags (
                name VARCHAR UNIQUE NOT NULL
            );
        SQL
        Database.execute(sql_query)
    end

    def process(flag)
        Database.add_data4insert(UseFlag.get_flag(flag))
    end

    def post_insert_task
        sql_query = 'select id from sources where source=?;'
        source_id = Database.get_1value(sql_query, '/etc/make.conf')
        type_id = Database.get_1value(UseFlag::SQL['type'], 'unknown')

        count_query = 'select count(id) from flags;'
        # http://bit.ly/tLQydk
        sql_query = <<-SQL
            INSERT INTO flags
            (name, type_id, source_id)
            SELECT tf.name, #{type_id}, #{source_id}
            FROM tmp_make_conf_flags tf
            WHERE NOT EXISTS (
                SELECT name FROM flags f WHERE f.name = tf.name
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
        INSERT OR IGNORE INTO tmp_make_conf_flags (name) VALUES (?);
    SQL
})

