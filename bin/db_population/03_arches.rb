#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'

def get_data(params)
    # result here
    arches = []
    # name of the file to be processed
    filename = File.join(params['profiles2_home'], 'arch.list')

    # walk through all use flags in that file
    IO.foreach(filename) do |line|
        # lets trim newlines
        line.chomp!()
        # skip empty lines and comments
        next if line.empty? or line.index('#') == 0
        # lets split flag and its description
        arch_stuff = line.split('-')
        # remember
        arches << [line, arch_stuff[0], arch_stuff[1] || 'linux']
    end

    return arches
end

def process(params)
    Database.add_data4insert(params['value'])
end

script = Script.new({
    'data_source' => method(:get_data),
    'thread_code' => method(:process),
    'sql_query' => <<SQL
INSERT INTO arches
(arch_name, architecture_id, platform_id)
VALUES (
    ?,
    (SELECT id FROM architectures WHERE architecture=?),
    (SELECT id FROM platforms WHERE platform_name=?)
);
SQL
})

