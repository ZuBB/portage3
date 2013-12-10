#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '606_installed_packages'
    self::SOURCE = '/var/db/pkg'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_installed_packages_ebuilds
            (version, package_id, repository_id, /*slot,*/ source_id)
            VALUES (?, ?, ?, /*?,*/ ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(InstalledPackage::DB_PATH, '*/*/')]
    end

    def set_shared_data
        request_data('repository@id', Repository::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'], true)
    end

    def process_item(item)
        category = InstalledPackage.get_file_content(item, 'CATEGORY')
        repo = InstalledPackage.get_file_content(item, 'repository')
       #slot = InstalledPackage.get_file_content(item, 'SLOT')
        pf = InstalledPackage.get_file_content(item, 'PF')
        package = Atom.get_package(pf)
        version = Atom.get_version(pf)

        send_data4insert({'data' => [
            version,
            shared_data('CPN@id', category + '/' + package),
            shared_data('repository@id', repo),
           #slot,
            shared_data('source@id', self.class::SOURCE),
        ]})
    end
end

Tasks.create_task(__FILE__, klass)
