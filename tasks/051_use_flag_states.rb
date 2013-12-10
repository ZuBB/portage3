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
        'insert' => 'INSERT INTO flag_states (state, status) VALUES (?, ?);'
    }

    def get_data(params)
        UseFlag::STATES
    end
end

Tasks.create_task(__FILE__, klass)

