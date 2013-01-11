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
    self::DEPENDS = '054_global_use_flags;'\
                    '055_local_use_flags;'\
                    '056_expand_use_flags;'\
                    '057_hidden_use_flags;'\
                    '058_arch_use_flags;'

    self::SQL = {
        'insert' => 'INSERT INTO flag_states (state, status) VALUES (?, ?);'
    }

    def get_data(params)
        []
    end
end

Tasks.create_task(__FILE__, klass)

