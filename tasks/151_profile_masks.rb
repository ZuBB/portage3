#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'mask'
require 'source'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources'
    self::SOURCE = 'profiles'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_profile_mask_categories
            (name, source_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(params['profiles_home'], '**/package.mask')]
        .reject { |i| File.exist?(i.sub('package.mask', 'deprecated')) }
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            result = Mask.parse_line(line.strip)
            send_data4insert({'data' => [
                result["category"],
                shared_data('source@id', self.class::SOURCE),
            ]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

