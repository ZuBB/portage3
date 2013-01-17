#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'installed_package'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources;602_installed_packages'
    self::SOURCE = '/var/db/pkg'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_installed_packages_categories
            (name, source_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(InstalledPackage::DB_PATH, '*/*/')]
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(item)
        if (category = InstalledPackage.get_file_content(item, 'CATEGORY'))
            send_data4insert({'data' => [
                category,
                shared_data('source@id', self.class::SOURCE),
            ]})
        else
            @logger.error("File `#{item}CATEGORY` is missed")
        end
    end
end

Tasks.create_task(__FILE__, klass)
