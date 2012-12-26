#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'useflag'
require 'source'
require 'repository'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources;021_repositories;053_use_flag_basic_stuff'
    self::SOURCE = 'profiles'
    self::REPO = 'gentoo'
    self::TYPE = 'global'

    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO flags
            (name, descr, type_id, source_id, repository_id)
            VALUES (?, ?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        IO.readlines(File.join(params['profiles_home'], 'use.desc'))
        .reject { |line| /^\s*#/ =~ line }
        .reject { |line| /^\s*$/ =~ line }
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('flag_type@id', UseFlag::SQL['@1'])
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
        Tasks::Scheduler.set_shared_data('repo@id', Repository::SQL['@'])
    end

    def process_item(line)
        unless (matches = UseFlag::REGEXPS[self.class::TYPE].match(line)).nil?
            params = *matches.to_a.drop(1)
            params << shared_data('flag_type@id', self.class::TYPE)
            params << shared_data('source@id', self.class::SOURCE)
            params << shared_data('repo@id', self.class::REPO)
            send_data4insert({'data' => params})
        else
            PLogger.group_log(@id, [
                [3, 'Failed to parse next line'],
                [1, line]
            ])
        end
    end
end

Tasks.create_task(__FILE__, klass)

