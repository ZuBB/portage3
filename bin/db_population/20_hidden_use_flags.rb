#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'parser'
require 'useflag'

def get_data(params)
    filename = File.join(params['profiles2_home'], 'base', 'make.defaults')
    content = IO.read(filename).split("\n")
    exceptions = Parser.get_multi_line_ini_value(content, 'USE_EXPAND_HIDDEN').split

    Dir.glob(File.join(params['profiles2_home'], 'desc', '*desc')).select { |file|
        exceptions.include?(File.basename(file, '.desc').upcase)
    }
end

class Script
    def pre_insert_task()
        flag_type = 'expand_hidden'
        flag_type_id = Database.get_1value(UseFlag::SQL['type'], flag_type)
        @shared_data['use_flag_types'] = {
            'expand_hidden_flag_type_id' => flag_type_id
        }
    end

    def process(file)
        use_prefix = File.basename(file, '.desc')
        flag_type_id = @shared_data['use_flag_types']['expand_hidden_flag_type_id']

        IO.foreach(file) do |line|
            next if line.start_with?('#') || /^\s*$/ =~ line

            matches = UseFlag::Regexps['hidden'].match(line.strip)
            unless matches.nil?
                matches = matches.to_a.drop(1)
                matches[0] = use_prefix + '_' + matches[0]
                Database.add_data4insert(*matches, flag_type_id)
            else
                PLogger.error("Failed to parse next line\n#{line}")
            end
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO use_flags
        (flag_name, flag_description, flag_type_id)
        VALUES (?, ?, ?);
    SQL
})

