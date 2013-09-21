#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/15/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => 'INSERT INTO keywords (name) VALUES (?);'
    }

    def get_data(params)
        Portage3::Keyword::LABELS
    end
end

Tasks.create_task(__FILE__, klass)

