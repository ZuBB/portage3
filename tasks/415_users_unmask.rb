#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/01/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '413_users_mask'
    self::SOURCE = '/etc/portage'
    self::FILE = 'package.unmask'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds_masks
            (ebuild_id, state_id, arch_id, profile_id, source_id)
            VALUES (?, ?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Portage3.package_asterisk_content(self.class::FILE)
    end

    def set_shared_data
        request_data('profile@id', Portage3::Profile::SQL['@'])
        request_data('mask_state@id', Portage3::Mask::SQL['@'])
        request_data('setting@id', Portage3::Setting::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('arch@id', Portage3::Keyword::SQL['@1'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line

        result = Atom.parse_atom_string(line.strip)
        result['state'] = Portage3::Mask.get_mast_state(result["prefix"])

        if (result['package_id'] = shared_data('CPN@id', result['atom'])).nil?
            @logger.warn("File `#{self.class::FILE}` has dead package: #{line.strip}")
            return
        end

        if (result_set = Atom.get_ebuilds(result)).size == 0
            @logger.warn("File `#{self.class::FILE}` has dead PV: #{line.strip}")
            return
        end

        result_set.each { |ebuild_id|
            send_data4insert({'data' => [
                ebuild_id,
                shared_data('mask_state@id', result['state']),
                shared_data('arch@id', shared_data('setting@id', 'arch')),
                shared_data('profile@id', shared_data('setting@id', 'profile')),
                shared_data('source@id', self.class::SOURCE)
            ]})
        }
    end
end

Tasks.create_task(__FILE__, klass)

