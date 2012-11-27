#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'installed_package'

klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_installed_packages_repos (name) VALUES (?);
        SQL
    }

    def get_data(params)
        Dir[File.join(InstalledPackage::DB_PATH, '**/*/')]
            .map { |item| item.sub(InstalledPackage::DB_PATH + '/', '') }
            .map { |item| item.sub(/\/$/, '') }
            .select { |item| item.count('/') == 1 }
    end

    def process_item(item)
        filepath_parts = [InstalledPackage::DB_PATH, item, 'repository']
        filepath = File.join(*filepath_parts)

        if File.size?(filepath)
            send_data4insert({'data' => [IO.read(filepath).strip]})
        else
            PLogger.error(@id, "File `#{filepath}` is missed")
        end
    end
end

Tasks.create_task(__FILE__, klass)

