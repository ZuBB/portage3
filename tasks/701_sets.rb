#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
klass = Class.new(Tasks::Runner) do
    self::SQL = {
        'insert' => 'INSERT INTO sets (name) VALUES (?);'
    }

    def get_data(params)
        sets = [].concat(Portage3::Set::SETS)
        sets_home = File.join(Portage3.portage_settings_home, 'sets')

        if File.exist?(sets_home) && File.directory?(sets_home)
            Dir[File.join(sets_home, '*')].each { |filename|
                sets << filename if File.size?(filename)
            }
        end

        sets
    end
end

Tasks.create_task(__FILE__, klass)

