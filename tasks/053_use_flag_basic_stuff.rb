#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    # metatask that depends on basic flags stuff
    self::DEPENDS = '008_sources;'\
                    '021_repositories;'\
                    '051_use_flag_states;'\
                    '052_use_flag_types'
    self::SQL = {
        'insert' => 'INSERT INTO flag_states (state, status) VALUES (?, ?);'
    }

    def get_data(params)
        []
    end
end

Tasks.create_task(__FILE__, klass)

