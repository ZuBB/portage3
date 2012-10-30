#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '001_architectures;002_platforms'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO arches
            (name, architecture_id, platform_id)
            VALUES (
                ?,
                (SELECT id FROM architectures WHERE name=?),
                (SELECT id FROM platforms WHERE name=?)
            );
        SQL
    }

    def get_data(params)
        IO.readlines(File.join(params['profiles_home'], 'arch.list'))
        .reject { |line| /^\s*#/ =~ line }
        .reject { |line| /^\s*$/ =~ line }
        .map do |line|
            line.strip!
            arch_stuff = line.split('-')
            [line, arch_stuff[0], arch_stuff[1] || 'linux']
        end
    end
end

Tasks.create_task(__FILE__, klass)

