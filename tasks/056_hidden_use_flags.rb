#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'parser'
require 'source'
require 'useflag'
require 'repository'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources;021_repositories;052_use_flag_types'
    self::SOURCE = 'profiles'
    self::REPO = 'gentoo'
    self::TYPE = 'hidden'

    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO flags
            (name, descr, type_id, source_id, repository_id)
            VALUES (?, ?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        filename = File.join(params['profiles_home'], 'base', 'make.defaults')
        content = IO.read(filename).split("\n")
        exceptions = Parser.get_multi_line_ini_value(content, 'USE_EXPAND_HIDDEN').split

        Dir.glob(File.join(params['profiles_home'], 'desc', '*desc')).select { |file|
            exceptions.include?(File.basename(file, '.desc').upcase)
        }
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('flag_type@id', UseFlag::SQL['@1'])
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
        Tasks::Scheduler.set_shared_data('repo@id', Repository::SQL['@'])
    end

    def process_item(file)
        use_prefix = File.basename(file, '.desc')
        type_id = shared_data('flag_type@id', self.class::TYPE)

        IO.foreach(file) do |line|
            next if line.start_with?('#') || /^\s*$/ =~ line

            unless (matches = UseFlag::REGEXPS[self.class::TYPE].match(line.strip)).nil?
                params = matches.to_a.drop(1)
                params << type_id
                params << shared_data('source@id', self.class::SOURCE)
                params << shared_data('repo@id', self.class::REPO)
                params[0] = use_prefix + '_' + params[0]

                if /\s{2,}/ =~ params[1]
                    PLogger.group_log(@id, [
                        [2, 'Got 2+ space chars in next line Fixing..'],
                        [1, params[1]]
                    ])
                    params[1].gsub!(/\s{2,}/, ' ')
                end

                send_data4insert({'data' => params})
            else
                PLogger.group_log(@id, [
                    [3, 'Failed to parse next line'],
                    [1, line]
                ])
            end
        end
    end
end

Tasks.create_task(__FILE__, klass)

