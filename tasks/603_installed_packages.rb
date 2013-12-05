#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '151_profile_categories'
    self::SOURCE = '/var/db/pkg'
    self::SQL = {
        'insert' => Category::SQL['insert'],
        'amount' => Category::SQL['amount']
    }

    def get_data(params)
        Dir[File.join(InstalledPackage::DB_PATH, '*/*/')]
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(item)
        category = InstalledPackage.get_file_content(item, 'CATEGORY')

        unless category
            @logger.error("File `#{item}CATEGORY` is missed")
            return
        end

        send_data4insert([
            category,
            shared_data('source@id', self.class::SOURCE)
        ])
    end
end

Tasks.create_task(__FILE__, klass)
