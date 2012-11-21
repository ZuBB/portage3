#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '095_ebuild_descriptions;098_ebuild_homepages'
    self::SQL = {
        'insert' => 'INSERT INTO tmp_etc_portage_flags_categories (category) VALUES (?);'
    }

    def get_data(params)
        # TODO hardcodede value
        IO.readlines('/etc/portage/package.use')
    end

    def process_item(line)
        if (/^\s*#/ =~ line).nil? && (/^\s*$/ =~ line).nil?
            send_data4insert({'data' => [line.split[0].split('/')[0]]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

