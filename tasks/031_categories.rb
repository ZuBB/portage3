#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources;021_repositories'
    self::SOURCE = 'portage tree'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO categories
            (name, descr, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        Category.get_categories(params)
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(params)
        @logger.debug("Category: #{params}")
        category = Category.new(params)

        params = [category.category]
        params << category.category_description
        params << shared_data('source@id', self.class::SOURCE)

        send_data4insert({'data' => params})
    end
end

Tasks.create_task(__FILE__, klass)

