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
    ITEM_TYPE = InstalledPackage::ITEM_TYPES['symlink'].dup

    def pre_insert_task
        @shared_data['itemtype@id'] =
            InstalledPackage.content_post_insert_check(ITEM_TYPE)
    end

    def process(param)
        iebuild_id = param[0]

        return unless (file = InstalledPackage.get_file(param, 'CONTENTS'))

        IO.foreach(file) do |cline|
            line = cline.dup
            next unless /^#{ITEM_TYPE}\s+/ =~ line

            type_id = @shared_data['itemtype@id'][ITEM_TYPE]
            line.sub!(/^#{ITEM_TYPE}/, '')

            line.sub!(/\d+\s*$/, '')
            time = $&.to_i

            parts = line.split('->').map { |i| i.strip }
            if parts.size != 2
                PLogger.group_log([
                    [3, 'Its something wrong with next item of type \'sym\''],
                    [1, cline],
                ])
                next
            end

            item_dir = File.dirname(parts[0])
            symlink_target = File.expand_path(File.join(item_dir, parts[1]))
            symlinkto = Database.get_1value(InstalledPackage::SQL['item_id'],
                                            symlink_target
                                           )
            Database.add_data4insert(iebuild_id, type_id, parts[0], symlinkto, time)
        end
    end
end

script = Script.new({
    'data_source' => InstalledPackage.method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO package_content
        (iebuild_id, type_id, item, symlinkto, install_time)
        VALUES (?, ?, ?, ?, ?);
    SQL
})

