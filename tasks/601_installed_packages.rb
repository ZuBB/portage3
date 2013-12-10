#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_installed_packages_repos
            (name, parent_folder, repository_folder)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(InstalledPackage::DB_PATH, '*/*/')]
    end

    def process_item(item)
        if (repo = InstalledPackage.get_file_content(item, 'repository'))
            send_data4insert({'data' => [repo, '/dev/null', repo]})
        else
            @logger.error("File `#{item}repository` is missed")
        end
    end
end

Tasks.create_task(__FILE__, klass)

