#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'installed_package'

class Script
    ITEM_TYPE = InstalledPackage::ITEM_TYPES['directory'].dup

    def pre_insert_task
        @shared_data['itemtype@id'] =
            InstalledPackage.content_post_insert_check(ITEM_TYPE)
    end

    def process(param)
        iebuild_id = param[0]

        return unless (file = InstalledPackage.get_file(param, 'CONTENTS'))

        IO.foreach(file) do |line|
            next unless /^#{ITEM_TYPE}\s+/ =~ line
            type_id = @shared_data['itemtype@id'][ITEM_TYPE]
            item = line.sub(/^#{ITEM_TYPE}/, '').strip
            Database.add_data4insert(iebuild_id, type_id, item)
        end
    end
end

script = Script.new({
    'data_source' => InstalledPackage.method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO package_content
        (iebuild_id, type_id, item)
        VALUES (?, ?, ?);
    SQL
})

