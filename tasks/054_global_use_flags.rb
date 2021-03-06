#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '053_use_flag_basic_stuff'
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

    def set_shared_data
        request_data('flag_type@id', UseFlag::SQL['@1'])
        request_data('source@id', Source::SQL['@'])
        request_data('repo@id', Repository::SQL['@'])
    end

    def process_item(line)
        unless (matches = line.match(/(.+) - (.+)/)).nil?
            params = *matches.to_a.drop(1)
            params << shared_data('flag_type@id', self.class::TYPE)
            params << shared_data('source@id', self.class::SOURCE)
            params << shared_data('repo@id', self.class::REPO)
            send_data4insert({'data' => params})
        else
            @logger.group_log([
                ['Failed to parse next line', 3],
                line
            ])
        end
    end
end

Tasks.create_task(__FILE__, klass)

