#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "table" => "use_flags",
    "script" => __FILE__
})

def fill_table(params)
    # pattern for flag, its description (and package)
    pattern = Regexp.new("([\\w\\/\\-]+:)?([\\w\\+\\-]+)(?: - )(.*)")

    ["use.desc", "use.local.desc"].each do |file|
        # get full filename
        filename = File.join(params["portage_home"], "profiles_v2", file)

        # read use flags and process each line
        (IO.read(filename).to_a rescue []).each do |line|
            # lets trim newlines
            line.chomp!()
            # skip comments or empty lines
            next if line.index('#') == 0 or line.empty?

            # lets get flag and desc
            match = pattern.match(line)

            Database.insert({
                "table" => params["table"],
                "command" => "INSERT OR REPLACE",
                "data" => {
                    "flag_name" => match[2],
                    "flag_description" => match[3],
                    "flag_type_id" => match[1].nil?() ? 1 : 2
                }
            })
        end
    end
end

script.fill_table_X(method(:fill_table))

