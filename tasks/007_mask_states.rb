#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
klass = Class.new(Tasks::Runner) do
    self::MASK_STATES = ['masked', 'unmasked']
    self::SQL = {
        'insert' => 'INSERT INTO mask_states (state) VALUES (?);'
    }

    def get_data(params)
        self.class::MASK_STATES
    end
end

Tasks.create_task(__FILE__, klass)

