#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#
klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => 'INSERT INTO architectures (name) VALUES (?);'
    }

    def get_data(params)
        IO.readlines(File.join(params['profiles_home'], 'arch.list'))
        .reject { |line| /^\s*#/ =~ line }
        .reject { |line| /^\s*$/ =~ line }
        .map { |line| line.split('-')[0].strip }
        .uniq
    end
end

Tasks.create_task(__FILE__, klass)

