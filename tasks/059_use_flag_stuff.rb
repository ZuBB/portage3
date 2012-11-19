#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    # metatask that depends on all flags stuff
    self::DEPENDS = '051_use_flag_states;'\
                    '052_use_flag_types;'\
                    '053_global_use_flags;'\
                    '054_local_use_flags;'\
                    '055_expand_use_flags;'\
                    '056_hidden_use_flags;'\
                    '057_arch_use_flags;'
    self::SQL = {
        'insert' => 'INSERT INTO flag_states (state, status) VALUES (?, ?);'
    }

    def get_data(params)
        []
    end
end

Tasks.create_task(__FILE__, klass)

