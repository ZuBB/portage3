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
        'insert' => 'INSERT INTO platforms (name) VALUES (?);'
    }

    def get_data(params)
        IO.readlines(File.join(params['profiles_home'], 'arch.list'))
        .reject { |line| /^\s*#/ =~ line }
        .reject { |line| /^\s*$/ =~ line }
        .select { |line| line.include?('-') }
        .map { |line| line.split('-')[1].strip }
        .uniq
    end
end

Tasks.create_task(__FILE__, klass)

