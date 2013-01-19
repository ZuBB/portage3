#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'installed_package'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '622_package_content'
    self::ITEM_TYPE = InstalledPackage::ITEM_TYPES['symlink']
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ipackage_content
            (iebuild_id, type_id, item, symlinkto, install_time)
            VALUES (?, ?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        InstalledPackage.get_data(params)
    end

    def set_shared_data
        request_data('itemtype@id', InstalledPackage::SQL['@1'])
        request_data('file_items@id', InstalledPackage::SQL['@2'])
    end

    def process_item(param)
        InstalledPackage.get_file_lines(param, 'CONTENTS')
        .select { |line| line.start_with?(self.class::ITEM_TYPE) }
        .each do |cline|
            line = cline.dup.sub(/^#{self.class::ITEM_TYPE}/, '')
            line.sub!(/\d+\s*$/, '')
            time = $&.to_i

            if (parts = line.split('->').map { |i| i.strip }).size != 2
                @logger.group_log([
                    [3, 'Its something wrong with next item of type \'sym\''],
                    cline,
                ])
                next
            end

            symlink_target = InstalledPackage.symlink_target(parts)
            symlink_target_id = shared_data('file_items@id', symlink_target)
            next unless symlink_target_id

            send_data4insert([
                param[0],
                shared_data('itemtype@id', self.class::ITEM_TYPE),
                parts[0],
                symlink_target_id,
                time
            ])
        end
    end
end

Tasks.create_task(__FILE__, klass)
