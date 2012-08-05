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
        type = 'sym'
        sql_query = 'SELECT id FROM content_item_types where type=?;'
        @shared_data['itemtype@id'] = {
            type => Database.get_1value(sql_query, type)
        }
    end

    def process(param)
        path = '/var/db/pkg'
        dir = File.join(path, param[1], param[2] + '-' + param[3])
        sql_query = 'select id from package_content where item=?'
        iebuild_id = param[0]

        IO.foreach(File.join(dir, 'CONTENTS')) do |line|
            next unless line.start_with?('sym')
            parts = line.split
            index = parts.index('->')

            if index.nil? || parts.size != 5
                PLogger.group_log([
                    [3, 'Its something wrong with next item of type \'sym\''],
                    [1, line],
                ])
                return
            end

            parts.delete_at(index)
            item_dir = File.dirname(parts[index - 1])
            symlink_target = File.expand_path(File.join(item_dir, parts[index]))
            parts[0] = @shared_data['itemtype@id'][parts[0]]
            parts[index] = Database.get_1value(sql_query, symlink_target)
            Database.add_data4insert(iebuild_id, *parts)
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO package_content
        (iebuild_id, type_id, item, symlinkto, install_time)
        VALUES (?, ?, ?, ?, ?);
    SQL
})

