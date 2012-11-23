#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/01/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'atom'
require 'mask'
require 'source'
require 'keyword'
require 'setting'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '413_users_mask'
    self::SOURCE = '/etc/portage'
    self::FILE = 'package.unmask'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds_masks
            (ebuild_id, arch_id, state_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        path_items = [Utils.get_portage_settings_home, self.class::FILE]
        IO.readlines(File.join(*path_items))
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('mask_state@id', Mask::SQL['@'])
        Tasks::Scheduler.set_shared_data('setting@id', Setting::SQL['@'])
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
       #Tasks::Scheduler.set_shared_data('arch@id', Keyword::SQL['@1'])
        Tasks::Scheduler.set_shared_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line

        result = Mask.parse_line(line.strip.insert(0, '-'))

        if (result['package_id'] = shared_data('CPN@id', result['atom'])).nil?
            PLogger.warn(@id, "File `#{self.class::FILE}` has dead package: #{line.strip}")
            return 
        end

        if (result_set = Atom.get_ebuilds(result)).size == 0
            PLogger.warn(@id, "File `#{self.class::FILE}` has dead PV: #{line.strip}")
            return
        end

        result_set.each { |ebuild_id|
            send_data4insert({'data' => [
                 ebuild_id,
                #shared_data('arch@id', shared_data('setting@id', 'arch')),
                 shared_data('setting@id', 'arch'),
                 shared_data('mask_state@id', result["state"]),
                 shared_data('source@id', self.class::SOURCE)
            ]})
        }
    end
end

Tasks.create_task(__FILE__, klass)

