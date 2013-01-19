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
    self::DEPENDS = '010_content_item_types;609_installed_packages'
    self::ITEM_TYPE = InstalledPackage::ITEM_TYPES['file']
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ipackage_content
            (iebuild_id, type_id, item, hash, install_time)
            VALUES (?, ?, ?, ?, ?);
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
        .each do |line|
            params = line.split
            params.unshift(param[0])
            params[1] = shared_data('itemtype@id', self.class::ITEM_TYPE)
            params[2] << ' ' + params.slice!(3..-3).join(' ')
            params[2].strip!
            send_data4insert(params)
        end
    end
end

Tasks.create_task(__FILE__, klass)
