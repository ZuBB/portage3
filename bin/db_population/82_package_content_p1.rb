#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    sql_query = <<-SQL
        SELECT ip.id, c.name, p.name, e.version
        FROM installed_packages ip
        JOIN ebuilds e ON e.id = ip.ebuild_id
        JOIN packages p ON e.package_id = p.id
        JOIN categories c ON p.category_id = c.id;
    SQL

    Database.select(sql_query)
end

class Script
    ITEM_TYPE = 'dir'
    def pre_insert_task
        sql_query = 'SELECT id FROM content_item_types where type=?;'
        @shared_data['itemtype@id'] = {
            ITEM_TYPE => Database.get_1value(sql_query, ITEM_TYPE)
        }
    end

    def process(param)
        path = '/var/db/pkg'
        dir = File.join(path, param[1], param[2] + '-' + param[3])
        iebuild_id = param[0]

        if !File.exist?(dir) || !File.directory?(dir)
            PLogger.error("'#{dir}' dir missed in '/var/db/pkg'")
        end

        IO.foreach(File.join(dir, 'CONTENTS')) do |line|
            next unless /^#{ITEM_TYPE}\s+/ =~ line
            type_id = @shared_data['itemtype@id'][ITEM_TYPE]
            item = line.sub(/^#{ITEM_TYPE}/, '').strip
            Database.add_data4insert(iebuild_id, type_id, item)
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO package_content
        (iebuild_id, type_id, item)
        VALUES (?, ?, ?);
    SQL
})

