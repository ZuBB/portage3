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
require 'profiles'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '006_profiles;007_mask_states;157_profile_masks'
    self::THREADS = 4
    self::SOURCE = 'profiles'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds_masks
            (ebuild_id, state_id, profile_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Portage3::Database.get_client.select(PProfile::SQL['names']).flatten
    end

    def set_shared_data
        request_data('profile@id', PProfile::SQL['@'])
        request_data('mask_state@id', Mask::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_file(filename, profile)
        @logger.debug("File: #{filename}")

        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            result = Mask.parse_line(line.strip)

            if (result['package_id'] = shared_data('CPN@id', result['atom'])).nil?
                @logger.warn("File `#{filename}` has dead package: #{line.strip}")
                next 
            end

            if (result_set = Atom.get_ebuilds(result)).size == 0
                @logger.warn("File `#{filename}` has dead PV: #{line.strip}")
                next
            end

            result_set.each { |ebuild_id|
                send_data4insert({'data' => [
                    ebuild_id,
                    shared_data('mask_state@id', result["state"]),
                    shared_data('profile@id', profile),
                    shared_data('source@id', self.class::SOURCE)
                ]})
            }
        end
    end

    def process_dir(path, profile)
        return if File.exist?(File.join(path, 'deprecated'))

        # we need to add base dir of profile also as source of data
        if File.size?(new_parent = File.join(path, 'parent'))
            IO.read(new_parent).lines.each do |relative_path|
                next if /^\s*#/ =~ relative_path
                next if /^\s*$/ =~ relative_path
                relative_path.strip!

                new_path = File.join(path, relative_path.strip)
                process_dir(File.realpath(new_path), profile)
            end
        end

        if File.exist?(package_mask_file = File.join(path, 'package.mask'))
            process_file(package_mask_file, profile)
        end
    end

    def process_item(profile)
        profile_path = File.join(Utils::get_profiles_home, profile)

        unless File.exist?(profile_path)
            @logger.error("Path #{profile_path} does not exist")
            return
        end

        if File.file?(profile_path)
            @logger.error("Path #{profile_path} is a file")
            return
        end

        process_dir(profile_path, profile)
    end
end

Tasks.create_task(__FILE__, klass)

