#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'useflag'

klass = Class.new(Tasks::Runner) do
    self::PRI_INDEX = 0.1
    self::SQL = {
        'insert' => 'INSERT INTO flag_states (state, status) VALUES (?, ?);'
    }

    def get_data(params)
        UseFlag::STATES
    end
end

Tasks.create_task(__FILE__, klass)

