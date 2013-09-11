#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/31/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'mask'

klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => 'INSERT INTO mask_states (state) VALUES (?);'
    }

    def get_data(params)
        Portage3::Mask::STATES
    end
end

Tasks.create_task(__FILE__, klass)

