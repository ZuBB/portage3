#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '006_profiles;007_mask_states;157_profile_ebuild_versions'
    self::TARGETS = ['package.mask']
    self::SOURCE  = 'profiles'
    self::THREADS = 4
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds_masks
            (ebuild_id, state_id, arch_id, profile_id, source_id)
            VALUES (?, ?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Portage3::Database.get_client.select(
            Portage3::Profile::SQL['names']).flatten
    end

    def set_shared_data
        request_data('profile@id', Portage3::Profile::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('profile@arch_id', Portage3::Profile::SQL['@2'])
        request_data('mask_state@id', Portage3::Mask::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(profile)
        Portage3::Profile.process_profile_dirs(profile, self.class::TARGETS)
        .uniq
        .each { |filename|
            IO.readlines(filename)
            .reject { |line| /^\s*#/ =~ line }
            .reject { |line| /^\s*$/ =~ line }
            .map    { |line| line.strip }
            .each   { |line|
                result = Atom.parse_atom_string(line)
                result['package_id'] = shared_data('CPN@id', result['atom'])
                result['state'] = Portage3::Mask.get_mast_state(result["prefix"])

                if result['package_id'].nil?
                    @logger.warn("File `#{filename}` has dead package: #{line}")
                    next
                end

                if (result_set = Atom.get_ebuilds(result)).empty?
                    @logger.warn("File `#{filename}` has dead PV: #{line}")
                    next
                end

                result_set.each { |ebuild_id|
                    send_data4insert({'data' => [
                         ebuild_id,
                         shared_data('mask_state@id', result['state']),
                         shared_data('profile@arch_id', profile),
                         shared_data('profile@id', profile),
                         shared_data('source@id', self.class::SOURCE)
                    ]})
                }
            }
        }
    end
end

Tasks.create_task(__FILE__, klass)

