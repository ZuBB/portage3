#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'useflag'
require 'profiles'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '006_profiles;059_use_flag_stuff'
    self::SOURCE  = 'profiles'
    self::ITEMS = ['use.force', 'use.mask']
    self::FLAG_TYPE = 'local'
    self::SQL = {
        # this is absolutely wrong
        # any of use.{force,mask} file should contain
        # ONLY GLOBAL FLAGS
        'insert' => <<-SQL
            INSERT INTO flags_states
            (profile_id, source_id, state_id, flag_id)
            SELECT DISTINCT ?, ?, ?, (
                    SELECT id
                    FROM flags
                    WHERE type_id == ? AND name=?
                );
        SQL
    }

    def get_data(params)
        Portage3::Database.get_client.select(PProfile::SQL['names']).flatten
    end

    def set_shared_data
        request_data('profile@id', PProfile::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('flag_state@id', UseFlag::SQL['@2'])
        request_data('flag_type@id', UseFlag::SQL['@1'])
    end

    def process_file(filename, profile)
        return unless File.size?(filename)

        IO.readlines(filename)
        .reject { |line| /^\s*#/ =~ line }
        .reject { |line| /^\s*$/ =~ line }
        .map { |line| line.strip }
        .each do |line|
            flag = UseFlag.get_flag(line)

            if filename.end_with?(self.class::ITEMS[0])
                state = UseFlag.get_flag_state3(line)
            elsif filename.end_with?(self.class::ITEMS[1])
                state = UseFlag.get_flag_state4(line)
            end

            send_data4insert([
                shared_data('profile@id', profile),
                shared_data('source@id', self.class::SOURCE),
                shared_data('flag_state@id', state),
                shared_data('flag_type@id', self.class::FLAG_TYPE),
                flag
            ])
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

                new_path = File.join(path, relative_path)
                process_dir(File.realpath(new_path), profile)
            end
        end

        use_force_file = File.join(path, self.class::ITEMS[0])
        use_mask_file = File.join(path, self.class::ITEMS[1])
        if File.exist?(use_force_file) || File.exist?(use_mask_file)
            process_file(use_force_file, profile)
            process_file(use_mask_file, profile)
        end
    end

    def process_item(profile)
        profile_path = File.join(Utils::get_profiles_home, profile)

        unless File.exist?(profile_path)
            PLogger.error("Path #{profile_path} does not exist")
            return
        end

        if File.file?(profile_path)
            PLogger.error("Path #{profile_path} is a file")
            return
        end

        process_dir(profile_path, profile)
    end
end

Tasks.create_task(__FILE__, klass)

