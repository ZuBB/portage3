#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '010_content_item_types;609_installed_packages'
    self::ITEM_TYPE = InstalledPackage::ITEM_TYPES['directory']
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ipackage_content
            (iebuild_id, type_id, item)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        InstalledPackage.get_data(params)
    end

    def set_shared_data
        request_data('itemtype@id', InstalledPackage::SQL['@1'])
    end

    def process_item(param)
        InstalledPackage.get_file_lines(param, 'CONTENTS')
        .select { |line| line.start_with?(self.class::ITEM_TYPE) }
        .each { |line|
            send_data4insert([
                param[0],
                shared_data('itemtype@id', self.class::ITEM_TYPE),
                line.sub(/^#{self.class::ITEM_TYPE}/, '').strip
            ])
        }
    end
end

Tasks.create_task(__FILE__, klass)
