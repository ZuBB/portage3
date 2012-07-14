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
require 'parser'
require 'useflag'

def get_data(params)
    # results go here
    results = []
    # pattern for flag, its description and package
    pattern = Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)')
    # flag type id
    flag_type_id = Database.get_1value(UseFlag::SQL['type'], 'expand_hidden')
    # items to construct ful path
    path_items = [params['profiles2_home'], 'desc', '*desc']
    # exceptions stuff
    exceptions = Parser.get_multi_line_ini_value(
        (IO.read(File.join(
            params['profiles2_home'], 'base', 'make.defaults'
        )).splait("\n")),
        'USE_EXPAND_HIDDEN'
    ).split(' ')

    # read use flags and process each line
    Dir.glob(File.join(*path_items)).each { |file|
        # get prefix for use flags in this file
        use_prefix = File.basename(file, '.desc')
        # skip if this file belongs to exceptions
        next unless exceptions.include?(use_prefix.upcase())
        # read use flags and process each line
        IO.foreach(file) do |line|
            # lets trim newlines
            line.chomp!()
            # skip comments or empty lines
            next if line.index('#') == 0 or line.empty?

            # lets get flag and desc
            match = pattern.match(line)
            # skip if we did not get a match
            next if match.nil?

            results << {
                'flag_name' => use_prefix + '_' + match[1],
                'flag_description' => match[2],
                'flag_type_id' => flag_type_id
            }
        end
    }

    return results
end

def process(params)
    Database.add_data4insert([
        params['value']['flag_name'],
        params['value']['flag_description'],
        params['value']['flag_type_id']
    ])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO use_flags (flag_name, flag_description, flag_type_id) VALUES (?, ?, ?);'
})

