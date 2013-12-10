#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '006_profiles;059_use_flag_stuff'
    self::TARGETS = ['use.force', 'use.mask']
    self::SOURCE  = 'profiles'
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
        Portage3::Database.get_client.select(
            Portage3::Profile::SQL['names']).flatten
    end

    def set_shared_data
        request_data('profile@id', Portage3::Profile::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('flag_state@id', UseFlag::SQL['@2'])
        request_data('flag_type@id', UseFlag::SQL['@1'])
    end

    def process_item(profile)
        Portage3::Profile.process_profile_dirs(profile, self.class::TARGETS)
        .each { |filename|
            IO.readlines(filename)
            .reject { |line| /^\s*#/ =~ line }
            .reject { |line| /^\s*$/ =~ line }
            .map    { |line| line.strip }
            .each   { |line|
                flag = UseFlag.get_flag(line)

                if filename.end_with?(self.class::TARGETS[0])
                    state = UseFlag.get_flag_state3(line)
                elsif filename.end_with?(self.class::TARGETS[1])
                    state = UseFlag.get_flag_state4(line)
                end

                send_data4insert([
                    shared_data('profile@id', profile),
                    shared_data('source@id', self.class::SOURCE),
                    shared_data('flag_state@id', state),
                    shared_data('flag_type@id', self.class::FLAG_TYPE),
                    flag
                ])
            }
        }
    end
end

Tasks.create_task(__FILE__, klass)

