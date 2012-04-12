#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/27/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "script" => __FILE__,
    "sql_query" => <<SQL
INSERT INTO arches
(arch_name, architecture_id, platform_id)
VALUES (
    ?,
    (SELECT id FROM architectures WHERE architecture=?),
    (SELECT id FROM platforms WHERE platform_name=?)
);
SQL
})

def fill_table(params)
    filename = File.join(params["portage_home"], "profiles", "arch.list")
    # walk through all use flags in that file
        (IO.read(filename).to_a rescue []).each do |line|
        # lets trim newlines
        line.chomp!()
        # skip empty lines and comments
        next if line.empty? or line.index('#') == 0

        # lets split flag and its description
        arch_stuff = line.split('-')
        # insert
        Database.insert({
            "sql_query" => params["sql_query"],
            "values" => [line, arch_stuff[0], arch_stuff[1] || 'linux']
        })
    end
end

script.fill_table_X(method(:fill_table))

