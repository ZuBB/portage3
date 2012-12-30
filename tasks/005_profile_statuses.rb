#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => 'INSERT INTO profile_statuses (status) VALUES (?);'
    }

    def get_data(params)
        path = File.join(params['profiles_home'], 'profiles.desc')
        IO.readlines(path)
        .reject { |line| line.start_with?('#') }
        .reject { |line| /^\s*$/ =~ line }
        .map { |line| line.split.last }
        .uniq
    end
end

Tasks.create_task(__FILE__, klass)

