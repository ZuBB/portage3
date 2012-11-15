#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
require 'ebuild_version'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '156_profile_masks'
    self::THREADS = 4
    self::SQL = {
        'insert' => 'UPDATE ebuilds SET version_order=? WHERE id=?;'
    }

    def get_data(params)
        EbuildVersion.get_data(params)
    end

    def process_item(params)
        versions = params['versions']
        atom = params['category'] + '/' + params['package']
        ordered_versions = versions.sort { |a, b|
            EbuildVersion.compare_versions_with_rbapi(a, b)
        }

        logged_items = [
            [1, "Package #{atom}"],
            [1, "original versions #{versions.inspect}"],
            [1, "sorted versions #{ordered_versions.inspect}"]
        ]

        versions.each_index do |index|
            ord_num = ordered_versions.index { |version|
                version == versions[index]
            }

            if !ord_num.nil?
                send_data4insert({'data' => [ord_num + 1, params['ids'][index]]})
            else
                logged_items << [3, "Version `#{versions[index]}` - 'cache miss'"]
            end
        end

        PLogger.group_log(@id, logged_items) if logged_items.size > 3
    end
end

Tasks.create_task(__FILE__, klass)

