#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#

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

    self::SQL['raw'] = <<-SQL
        SELECT id
        FROM ipackage_content
        WHERE item = ? and iebuild_id = ?
    SQL

    def get_data(params)
        InstalledPackage.get_data(params)
    end

    def set_shared_data
        request_data('itemtype@id', InstalledPackage::SQL['@1'])
        request_data('dir_items@id', InstalledPackage::SQL['@3'])
        request_data('file_items@id', InstalledPackage::SQL['@2'])
    end

    def process_line(ebuild_id, cline, deep_check)
        line = cline.dup.sub(/^#{self.class::ITEM_TYPE}/, '')
        line.sub!(/\d+\s*$/, '')
        time = $&.to_i

        if (parts = line.split('->').map { |i| i.strip }).size != 2
            @logger.group_log([
                [3, 'Its something wrong with next item of type \'sym\''],
                cline,
            ])
            return true
        end

        symlink_target = InstalledPackage.symlink_target(parts)
        symlink_target_id =
            shared_data('file_items@id', symlink_target) ||
            shared_data('dir_items@id', symlink_target)

        if deep_check
            symlink_target_id = @database.get_1value(
                self.class::SQL['raw'], symlink_target, ebuild_id
            )
        end

        return false if symlink_target_id.nil?

        send_data4insert([
            ebuild_id,
            shared_data('itemtype@id', self.class::ITEM_TYPE),
            parts[0],
            symlink_target_id,
            time
        ])

        return true
    end

    def process_item(param)
        symlink2 = InstalledPackage.get_file_lines(param, 'CONTENTS')
        .select { |line| line.start_with?(self.class::ITEM_TYPE) }
        .map { |line| process_line(param[0], line, false) ? nil : line }
        .compact

        sleep(1) if symlink2.size > 0

        while symlink2.size > 0
            size_before = symlink2.size

            symlink2
            .map! { |line| process_line(param[0], line, true) ? nil : line }
            .compact!

            size_after = symlink2.size
            if size_before == size_after
                @logger.error('did not found next items')
                @logger.info(symlink2.to_s)
                break
            end
        end
    end
end

Tasks.create_task(__FILE__, klass)
