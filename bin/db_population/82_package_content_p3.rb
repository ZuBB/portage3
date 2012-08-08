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
    ITEM_TYPE = 'sym'

    def pre_insert_task
        sql_query = 'SELECT id FROM content_item_types where type=?;'
        @shared_data['itemtype@id'] = {
            ITEM_TYPE => Database.get_1value(sql_query, ITEM_TYPE)
        }
    end

    def process(param)
        path = '/var/db/pkg'
        dir = File.join(path, param[1], param[2] + '-' + param[3])
        sql_query = 'select id from package_content where item=?'
        iebuild_id = param[0]

        if !File.exist?(dir) || !File.directory?(dir)
            PLogger.error("'#{dir}' dir missed in '#{path}'")
        end

        IO.foreach(File.join(dir, 'CONTENTS')) do |line|
            next unless /^#{ITEM_TYPE}\s+/ =~ line

            type_id = @shared_data['itemtype@id'][ITEM_TYPE]
            line.sub!(/^#{ITEM_TYPE}/, '')

            line.sub!(/\d+\s*$/, '')
            time = $&.to_i

            parts = line.split('->').map { |i| i.strip }
            if parts.size != 2
                PLogger.group_log([
                    [3, 'Its something wrong with next item of type \'sym\''],
                    [1, line],
                ])
                next
            end

            item_dir = File.dirname(parts[0])
            symlink_target = File.expand_path(File.join(item_dir, parts[1]))
            symlinkto = Database.get_1value(sql_query, symlink_target)
            Database.add_data4insert(iebuild_id, type_id, parts[0], symlinkto, time)
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

