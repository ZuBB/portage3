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
require 'package_module'
require 'category_module'

def get_data(params)
    # results go here
    results = []
    # pattern for flag, its description and package
    pattern = Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?: - )(.*)")
    # flag type id
    flag_type_id = Database.get_1value(UseFlag::SQL['type'], 'local')

    # read use flags and process each line
    IO.foreach(File.join(params['profiles2_home'], 'use.local.desc')) do |line|
        # lets trim newlines
        line.chomp!()
        # skip comments or empty lines
        next if line.index('#') == 0 or line.empty?
        # lets get flag and desc
        match = pattern.match(line)

        results << {
            'flag_name' => match[2],
            'flag_description' => match[3],
            'flag_type_id' => flag_type_id,
            'package_id' => Database.get_1value(
                PackageModule::SQL['id'],
                [
                    match[1].split('/')[1][0..-2],
                    Database.get_1value(
                        CategoryModule::SQL['id'],
                        match[1].split('/')[0]
                    )
                ]
            )
        }
    end

    return results
end

def process(params)
    Database.add_data4insert([
        params['value']['flag_name'],
        params['value']['flag_description'],
        params['value']['flag_type_id'],
        params['value']['package_id']
    ])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO use_flags (flag_name, flag_description, flag_type_id, package_id) VALUES (?, ?, ?, ?);'
})

