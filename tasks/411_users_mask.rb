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
    self::DEPENDS = '041_packages'
    self::SOURCE = '/etc/portage'
    self::REPO = 'unknown'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_etc_portage_mask_ebuilds
            (version, package_id, repository_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        ['package.mask', 'package.unmask']
        .map { |file| Portage3.package_asterisk_content(file) }
        .flatten
    end

    def set_shared_data
        request_data('repository@id', Repository::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line

        result = Mask.parse_line(line.strip)

        return if result['vrestr'].nil?
        return if result['version'].nil?
        return if result['version'].end_with?('*')

        send_data4insert({'data' => [
            result["version"].strip,
            shared_data('CPN@id', result['atom']),
            shared_data('repository@id', self.class::REPO),
            shared_data('source@id', self.class::SOURCE)
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

