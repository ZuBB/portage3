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
    TYPE = 'expand'

    def pre_insert_task
        @shared_data.merge!(UseFlag.pre_insert_task(TYPE))
    end

    def process(file)
        use_prefix = File.basename(file, '.desc')
        type_id = @shared_data['flag_type@id'][TYPE]

        IO.foreach(file) do |line|
            next if line.start_with?('#') || /^\s*$/ =~ line

            if /\s{2,}/ =~ line
                PLogger.group_log([
                    [2, 'Got 2+ space chars in next line Fixing..'],
                    [1, line]
                ])
                line.gsub!(/\s{2,}/, ' ')
            end

            unless (matches = UseFlag::REGEXPS[TYPE].match(line.strip)).nil?
                params = matches.to_a.drop(1)
                params << type_id
                params << @shared_data['source@id']['profiles']
                params << @shared_data['repo@id']['gentoo']
                params[0] = use_prefix + '_' + params[0]
                Database.add_data4insert(*params)
            else
                PLogger.group_log([
                    [3, 'Failed to parse next line'],
                    [1, line]
                ])
            end
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO flags
        (name, descr, type_id, source_id, repository_id)
        VALUES (?, ?, ?, ?, ?);
    SQL
})

