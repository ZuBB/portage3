#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'atom'
require 'mask'
require 'source'
require 'repository'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '021_repositories;154_profile_masks'
    self::SOURCE = 'profiles'
    self::REPO = 'unknown'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_profile_mask_ebuilds
            (package_id, version, repository_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Dir[File.join(params['profiles_home'], '**/package.mask')]
        .reject { |i| File.exist?(i.sub('package.mask', 'deprecated')) }
    end

    def set_shared_data
        request_data('repository@id', Repository::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            result = Mask.parse_line(line.strip)

            next if result['vrestr'].nil?
            next if !result['vrestr'].eql?('=')
            next if result['version'].end_with?('*')

            send_data4insert({
                'data' => [
                    shared_data('CPN@id', result['atom']),
                    result["version"].strip,
                    shared_data('repository@id', self.class::REPO),
                    shared_data('source@id', self.class::SOURCE)
                ]
            })
        end
    end
end

Tasks.create_task(__FILE__, klass)

