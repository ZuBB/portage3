#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'

def get_data(params)
    Database.select('SELECT name from profiles;').flatten
end

class Script
    # find ${PORTDIR}/profiles -name 'use*' -printf "%f\n" | sort -u | grep -v -e desc
    #   use.force
    #   use.mask
    # TODO do we need a Hash here?
    ITEMS = ['use.force', 'use.mask']
    SOURCE = 'profiles'
    FLAG_TYPE = 'local'

    def pre_insert_task
        sql_query = 'SELECT name, id FROM profiles;'
        @shared_data['profile@id'] = Hash[Database.select(sql_query)]

        sql_query = 'SELECT state, id FROM flag_states;'
        @shared_data['flag_state@id'] = Hash[Database.select(sql_query)]

        sql_query = 'SELECT source, id FROM sources;'
        @shared_data['source@id'] = Hash[Database.select(sql_query)]

        sql_query = 'SELECT type, id FROM flag_types;'
        @shared_data['flag_type@id'] = Hash[Database.select(sql_query)]
    end

    def process(profile)
        def process_dir(path, profile_path)
            # skip dirs that has 'deprecated' file in it
            return if File.exist?(File.join(path, 'deprecated'))

            ITEMS.each do |key|
                filepath = File.join(path, key)
                next unless File.size?(filepath)

                IO.foreach(filepath) do |line|
                    next if /^\s*#/ =~ line
                    next if /^\s*$/ =~ line
                    line.strip!
                    flag = UseFlag.get_flag(line)

                    if key == 'use.force'
                        state = UseFlag.get_flag_state3(line)
                    elsif key == 'use.mask'
                        state = UseFlag.get_flag_state4(line)
                    end

                    params = [@shared_data['profile@id'][profile_path]]
                    params << @shared_data['source@id'][SOURCE]
                    params << @shared_data['flag_state@id'][state]
                    params << @shared_data['flag_type@id'][FLAG_TYPE]
                    params << flag

                    Database.add_data4insert(*params)
                end
            end

            # we need to add base dir of profile also as source of data
            if File.size?(new_parent = File.join(path, 'parent'))
                IO.read(new_parent).lines.each do |relative_path|
                    next if /^\s*#/ =~ relative_path
                    next if /^\s*$/ =~ relative_path
                    relative_path.strip!

                    new_path = File.join(path, relative_path.strip)
                    process_dir(File.realpath(new_path), profile_path)
                end
            end
        end

        profile_path = File.join(Utils::get_profiles_home, profile)

        # checks if we processing profile
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

script = Script.new({
    'data_source' => method(:get_data),
    "sql_query" => <<-SQL
        INSERT INTO flags_states
        (profile_id, source_id, state_id, flag_id)
        VALUES (?, ?, ?, (
                SELECT id
                FROM flags
                WHERE type_id != ? AND name=?
                ORDER BY type_id ASC
                LIMIT 1
            ));
    SQL
})

