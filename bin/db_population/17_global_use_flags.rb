#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'
require 'useflag'

def get_data(params)
    # results go here
    results = []
    # pattern for flag, its description
    pattern = Regexp.new('([\\w\\+\\-]+)(?: - )(.*)')
    # flag type id
    flag_type_id = Database.get_1value(UseFlag::SQL['type'], 'global')

    # read use flags and process each line
    IO.foreach(File.join(params['profiles2_home'], 'use.desc')) do |line|
        # lets trim newlines
        line.chomp!()
        # skip comments or empty lines
        next if line.index('#') == 0 or line.empty?
        # lets get flag and desc
        match = pattern.match(line)

        results << {
            'flag_name' => match[1],
            'flag_description' => match[2],
            'flag_type_id' => flag_type_id
        }
    end

    return results
end

def process(params)
    Database.add_data4insert([
        params['value']['flag_name'],
        params['value']['flag_description'],
        params['value']['flag_type_id']
    ])
end

def check_global_flag_duplicates()
    flag_type_id = Database.get_1value(UseFlag::SQL['type'], 'global')
    sql_query = "SELECT COUNT(id) FROM use_flags WHERE flag_type_id=#{flag_type_id}"
    total_global_flags = Database.db().get_first_value(sql_query)
    sql_query = "SELECT COUNT(DISTINCT flag_name) FROM use_flags WHERE flag_type_id=#{flag_type_id}"
    unique_global_flags = Database.get_1value(sql_query)

    if total_global_flags != unique_global_flags
        PLogger.error('Its very likely that global flags have duplicates')
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO use_flags (flag_name, flag_description, flag_type_id) VALUES (?, ?, ?);'
})

# have to comment out this as it runs query on closed db
#check_global_flag_duplicates()
