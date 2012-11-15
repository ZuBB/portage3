#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '095_ebuild_descriptions;098_ebuild_homepages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_profile_mask_packages
            (package, category_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(params['profiles_home'], '**/package.mask')]
        .reject { |i| File.exist?(i.sub('package.mask', 'deprecated')) }
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('category@id', Category::SQL['@'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            result = Mask.parse_line(line.strip)
            send_data4insert({'data' => [
                result["package"].strip,
                shared_data('category@id', result["category"])
            ]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

