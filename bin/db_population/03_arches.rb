#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []
    filename = File.join(params['profiles_home'], 'arch.list')

    IO.foreach(filename) do |line|
        line.strip!
        next if line.empty?
        next if line.start_with?('#')
        arch_stuff = line.split('-')
        results << [line, arch_stuff[0], arch_stuff[1] || 'linux']
    end

    results
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<SQL
INSERT INTO arches
(name, architecture_id, platform_id)
VALUES (
    ?,
    (SELECT id FROM architectures WHERE name=?),
    (SELECT id FROM platforms WHERE name=?)
);
SQL
})

