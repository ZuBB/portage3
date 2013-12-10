#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => 'INSERT INTO content_item_types (type) VALUES (?);'
    }

    def get_data(params)
        InstalledPackage::ITEM_TYPES.values
    end
end

Tasks.create_task(__FILE__, klass)

