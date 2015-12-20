#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/20/12
# Latest Modification: Vasyl Zuzyak, ...
#
klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '003_arches;005_profile_statuses'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO profiles
            (arch_id, name, status_id)
            VALUES (
                (SELECT id FROM arches WHERE name=?),
                ?,
                (SELECT id FROM profile_statuses WHERE status=?)
            );
        SQL
    }

    def get_data(params)
        results = []
        filename = File.join(params['profiles_home'], 'profiles.desc')

        IO.foreach(filename) do |line|
            # skip comments
            next if line.start_with?('#')
            # skip empty lines
            next if /^\s*$/ =~ line

            # TODO uclibc/embedded multiarch profiles

            results << [*line.sub('#', '').strip.split]
        end

        results
    end
end

Tasks.create_task(__FILE__, klass)

