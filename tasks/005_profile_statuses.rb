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
        'insert' => 'INSERT INTO profile_statuses (status) VALUES (?);'
    }

    def get_data(params)
        path = File.join(params['profiles_home'], 'profiles.desc')
        results = %x[grep -oP '\t[a-z]*$' #{path}].split("\n") rescue []
        # drop first item since its a header
        results.shift
        # drop duplicates and strip leading \t
        results.uniq.map { |status| status.strip }
    end
end

Tasks.create_task(__FILE__, klass)

