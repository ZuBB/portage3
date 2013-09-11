#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'atom'
require 'source'
require 'keyword'
require 'setting'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '091_ebuilds'
    self::SOURCE = '/etc/portage'
    self::TYPE = 'unknown'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds_keywords
            (ebuild_id, arch_id, keyword_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Portage3.package_asterisk_content('package.keywords')
    end

    def set_shared_data
        request_data('setting@id', Portage3::Setting::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line

        arch = shared_data('setting@id', 'arch')
        keyword = shared_data('setting@id', 'keyword')
        result = Keyword.parse_line(line.strip, arch, keyword)

        
        if (result['package_id'] = shared_data('CPN@id', result['atom'])).nil?
            @logger.warn("Dead package: #{line.strip}")
            return
        end

        if (result_set = Atom.get_ebuilds(result)).nil?
            @logger.warn("Dead PV: #{line.strip}")
            return
        end

        result_set.each { |ebuild_id|
            send_data4insert({'data' => [
                ebuild_id,
                arch,
                keyword,
                shared_data('source@id', self.class::SOURCE)
            ]})
        }
    end
end

Tasks.create_task(__FILE__, klass)

