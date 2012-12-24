#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/16/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'package'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '031_categories'
    self::SOURCE = 'portage tree'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO packages
            (name, category_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        Package.get_packages(params)
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(params)
        @logger.debug("Package: #{params}")
        package = Package.new(params)

        params = [package.package]
        params << package.category_id
        params << shared_data('source@id', self.class::SOURCE)

        send_data4insert({'data' => params})
    end
end

Tasks.create_task(__FILE__, klass)

