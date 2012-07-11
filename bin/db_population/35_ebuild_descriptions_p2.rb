#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'
require 'ebuild'

def get_data(params)
    # results
    results = []
    # query
    sql_query = <<-SQL
        SELECT
            parent_folder,
            repository_folder,
            category_name,
            package_name,
            version
        FROM ebuilds e
        JOIN packages p on p.id=e.package_id
        JOIN categories c on p.category_id=c.id
        JOIN repositories r on r.id=e.repository_id
    SQL

    # lets walk through all packages
    Database.select(sql_query).each { |row|
        results << {
            'value' => row[3] + '-' + row[4] + '.ebuild',
            'parent_dir' => File.join(row[0], row[1], row[2], row[3])
        }
    }

    return results
end

def process(params)
    PLogger.info("Ebuild: #{params["value"]}")
    ebuild = Ebuild.new(params)

    Database.add_data4insert(
        [ebuild.ebuild_description(), ebuild.ebuild_id()]
    )
end

script = Script.new({
    'thread_code' => method(:process),
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        UPDATE ebuilds
        SET description_id=(
            select id from ebuild_descriptions where description=?
        )
        WHERE id=?;
    SQL
})

