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
    path = '/var/db/pkg'
    Dir[File.join(path, '**/*/')].select do |item|
        item.sub!(path + '/', '')
        item.sub!(/\/$/, '')
        item.count('/') == 1
    end
end

class Script
    def pre_insert_task
        @shared_data['atom@id'] = {}
        sql_query = <<-SQL
            SELECT e.id, c.category_name, p.package_name, e.version
            FROM ebuilds e
            JOIN packages p ON e.package_id = p.id
            JOIN categories c ON p.category_id = c.id;
        SQL
        Database.select(sql_query).each do |row|
            key = row[1] + '/' + row[2] +  '-' + row[3]
            @shared_data['atom@id'][key] = row[0]
        end
    end

    def process(item)
        ebuild_id = @shared_data['atom@id'][item]

        item_path  = File.join('/var/db/pkg', item)
        pkgsize    = IO.read(File.join(item_path, 'SIZE')).strip
        binpkgmd5  = IO.read(File.join(item_path, 'BINPKGMD5')).strip rescue nil
        build_time = IO.read(File.join(item_path, 'BUILD_TIME')).strip

        Database.add_data4insert(ebuild_id, build_time, binpkgmd5, pkgsize)
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO installed_packages
        (ebuild_id, build_time, binpkgmd5, pkgsize)
        VALUES (?, ?, ?, ?);
    SQL
})

