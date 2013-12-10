#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '603_installed_packages'
    self::SOURCE = '/var/db/pkg'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_installed_packages_packages
            (name, category_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(InstalledPackage::DB_PATH, '*/*/')]
    end

    def set_shared_data
        request_data('category@id', Category::SQL['@'])
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(item)
        category = InstalledPackage.get_file_content(item, 'CATEGORY')
        # NOTE for some reason Portage does not create 'PACKAGE' files...
        pf = InstalledPackage.get_file_content(item, 'PF')

        if pf && category
            send_data4insert({'data' => [
                Atom.get_package(pf),
                shared_data('category@id', category),
                shared_data('source@id', self.class::SOURCE)
            ]})
        else
            @logger.error("File `#{item}PACKAGE` is missed")
        end
    end
end

Tasks.create_task(__FILE__, klass)
