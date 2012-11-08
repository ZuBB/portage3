#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
klass = Class.new(Tasks::Runner) do
    self::SWITCHES = ['none', 'or', 'if']
    self::SQL = {
        'insert' => 'INSERT INTO switch_types (type) VALUES (?);'
    }

    def get_data(params)
        self.class::SWITCHES
    end
end

Tasks.create_task(__FILE__, klass)

