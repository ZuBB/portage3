#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '095_ebuild_descriptions;098_ebuild_homepages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_etc_portage_flags_package
            (package, category_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        IO.readlines('/etc/portage/package.use')
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('category@id', Category::SQL['@'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line

        category, package = *line.split[0].split('/')
        send_data4insert({'data' => [
            package.strip,
            shared_data('category@id', category)
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

