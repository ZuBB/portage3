#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
require_relative 'envsetup'
require 'ebuild'

def get_data(params)
    tmp_results = {}

    Ebuild.get_ebuilds.each do |row|
        package_id = row[7]
        unless tmp_results.has_key?(package_id)
            tmp_results[package_id] = {
                'category' => row[3],
                'package'  => row[4],
                'versions' => [],
                'ids'      => []
            }
        end

        tmp_results[package_id]['versions'] << row[5]
        tmp_results[package_id]['ids'] << row[6]
    end

    tmp_results.values
end

def sort_versions_with_eix(atom)
    versions_line = %x[eix -x --end #{atom} | grep 'Available versions']

    # drop wording at start
    versions_line.sub!('Available versions:', '')

    # drop use flags
    versions_line.sub!(/\{[^\}]+\}\s*$/, "")

    # get versions and make it looks nice
    versions_line.strip().split(' ').map! { |version|
        version.sub!(/!.+/, '')
        version.gsub!(/\([^\)]+\)/, '')
        version.gsub!(/\[[^\]]+\]/, '')
        version.sub!(/\+[iv]$/, '')
        version.sub!(/[~*]+/, '')
        version
    }
end

class Script
    def pre_insert_task
        sql_query = <<-SQL
            CREATE TABLE IF NOT EXISTS tmp_ebuild_versions (
                id INTEGER,
                ebuild_id INTEGER NOT NULL,
                package_id INTEGER NOT NULL,
                version VARCHAR NOT NULL,
                version_order INTEGER NOT NULL,
                version_order_eix INTEGER NOT NULL,
                version_order_api INTEGER NOT NULL,
                PRIMARY KEY (id)
            );
        SQL
        Database.execute(sql_query)

        sql_query = 'select count(id) from tmp_ebuild_versions'
        count = Database.get_1value(sql_query)

        if count == 0
            sql_query = <<-SQL
                insert into tmp_ebuild_versions
                (ebuild_id, package_id, version, version_order)
                select ebuild_id, version, version_order
                from ebuilds;
            SQL
            Database.execute(sql_query)
        end
    end

    def process(params)
        versions = params['versions']
        atom = params['category'] + '/' + params['package']
        ordered_versions = sort_versions_with_eix(atom)

        PLogger.info("Package #{atom}")
        PLogger.info("versions #{ordered_versions.inspect}")

        versions.each_index do |index|
            ord_num = ordered_versions.index { |version|
                version == versions[index]
            }

            if !ord_num.nil?
                Database.add_data4insert([ord_num + 1, params['ids'][index]])
            else
                PLogger.warn("Version `#{versions[index]}` - 'cache miss'")
            end
        end
    end

    def post_insert_check
        sql_query = <<-SQL
            select c.category_name, p.package_name
            from tmp_ebuild_versions e
            join packages p on e.package_id=p.id
            join categories c on p.category_id=c.id
            where
                version_order != version_order_eix and
                version_order_eix > 0;
            group by package_id;
        SQL

        if (mismatches = Database.select(sql_query)).size > 0
            PLogger.error("There are disparities in version orders for next packages")
            mismatches.each { |row| PLogger.info(row[0] + '/' + row[1]) }
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'UPDATE tmp_ebuild_versions SET version_order_eix=? WHERE id=?;'
})

