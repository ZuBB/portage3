#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '608_installed_packages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO installed_packages
            (ebuild_id, pkgsize, build_time, binpkgmd5)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(InstalledPackage::DB_PATH, '*/*/')]
        .map { |item| item.sub(/^#{InstalledPackage::DB_PATH}\//, '') }
        .map { |item| item.sub(/\/$/, '') }
    end

    def set_shared_data
        request_data('CPF@id', Atom::SQL['@2'])
    end

    def process_item(item)
        item_path = File.join(InstalledPackage::DB_PATH, item)

        send_data4insert([
            shared_data('CPF@id', item),
            InstalledPackage.get_file_content(item_path, 'SIZE'),
            InstalledPackage.get_file_content(item_path, 'BUILD_TIME'),
            InstalledPackage.get_file_content(item_path, 'BINPKGMD5')
        ])
    end
end

Tasks.create_task(__FILE__, klass)
