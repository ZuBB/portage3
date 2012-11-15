#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'atom'
require 'package'
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '152_profile_masks;154_profile_masks'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_profile_mask_ebuilds
            (package_id, version)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(params['profiles_home'], '**/package.mask')]
        .reject { |i| File.exist?(i.sub('package.mask', 'deprecated')) }
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            result = Mask.parse_line(line.strip)

            next if result['vrestr'].nil?
            next if result['vrestr'].eql?('=')
            next if result['version'].nil?

            send_data4insert({
                'raw_data' => [result['atom'], result["version"]],
                'data' => [
                    shared_data('CPN@id', result['atom']),
                    result["version"].strip
                ]
            })
        end
    end
end

Tasks.create_task(__FILE__, klass)

