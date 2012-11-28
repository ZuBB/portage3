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
        'insert' => 'INSERT INTO eapis (version) VALUES (?);'
    }

    def get_data(params)
        # http://www.gentoo.org/proj/en/qa/pms.xml
        results = []
        search_path = "#{params['tree_home']}/*/*/*ebuild"
        # lets find line from all ebuilds that have string with EAPI at 0 position
        grep_command = "grep -h '^EAPI' #{search_path} 2> /dev/null"

        for letter in 'a'..'z'
            results += %x[#{grep_command.sub(/\*/, "#{letter}*")}].split("\n")
        end

        results.uniq.map { |line|
            line.sub(/#.*$/, '').gsub(/["' EAPI=]/, '')
        }.uniq
    end
end

Tasks.create_task(__FILE__, klass)

