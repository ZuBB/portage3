#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'
require 'parser'

def get_data(params)
    filename = File.join(params['profiles2_home'], 'base', 'make.defaults')
    content = IO.read(filename).split("\n")
    exceptions = Parser.get_multi_line_ini_value(content, 'USE_EXPAND_HIDDEN').split

    Dir.glob(File.join(params['profiles2_home'], 'desc', '*desc')).reject { |file|
        exceptions.include?(File.basename(file, '.desc').upcase)
    }
end

class Script
    def pre_insert_task()
        type = 'expand'
        type_id = Database.get_1value(UseFlag::SQL['type'], type)
        @shared_data['flag_type@id'] = { type => type_id }
    end

    def process(file)
        use_prefix = File.basename(file, '.desc')
        type_id = @shared_data['flag_type@id']['expand']

        IO.foreach(file) do |line|
            next if line.start_with?('#') || /^\s*$/ =~ line

            if /\s{2,}/ =~ line
                PLogger.warn("Got 2+ spaces in next line. Fixing..\n`#{line}`")
                line.gsub!(/\s{2,}/, ' ')
            end

            unless (matches = UseFlag::Regexps['expand'].match(line.strip)).nil?
                matches = matches.to_a.drop(1)
                matches[0] = use_prefix + '_' + matches[0]
                Database.add_data4insert(*matches, type_id)
            else
                PLogger.error("Failed to parse next line\n#{line}")
            end
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO flags (name, descr, type_id) VALUES (?, ?, ?);'
})

