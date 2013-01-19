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
    self::DEPENDS = '623_package_content'
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
        request_data('symlink_items@id', InstalledPackage::SQL['@3'])
    end

    def process_item(param)
        InstalledPackage.get_file_lines(param, 'CONTENTS')
        .select { |line| line.start_with?(self.class::ITEM_TYPE) }
        .select { |line| shared_data('symlink_items@id', line.split[1]).nil? }
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
            symlink_target_id = shared_data('symlink_items@id', symlink_target)
            unless symlink_target_id
				@logger.unknown(cline)
				next 
			end

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
