#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'atom'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '041_packages'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_etc_portage_mask_ebuilds
            (package_id, version)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        lines = []

        ['package.mask', 'package.unmask'].each do |file|
            filepath = File.join(Utils.get_portage_settings_home, file)
            lines += IO.readlines(filepath) if File.size?(filepath)
        end

        lines
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line

        result = Mask.parse_line(line.strip)

        return if result['vrestr'].nil?
        return if result['vrestr'].eql?('=')
        return if result['version'].nil?

        send_data4insert({
            'raw_data' => [result['atom'], result["version"]],
            'data' => [
                shared_data('CPN@id', result['atom']),
                result["version"].strip
            ]
        })
    end
end

Tasks.create_task(__FILE__, klass)

