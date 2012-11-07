#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'

klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => 'INSERT INTO sources (source) VALUES (?);'
    }

    def get_data(params)
        Source::SOURCES
    end
end

Tasks.create_task(__FILE__, klass)

