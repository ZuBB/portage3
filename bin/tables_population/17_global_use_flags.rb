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
    "script" => __FILE__,
    "helper_query1" => "SELECT id FROM use_flags_types WHERE flag_type=?"
})

def fill_table(params)
    # pattern for flag, its description
    pattern = Regexp.new("([\\w\\+\\-]+)(?: - )(.*)")
    # flag type id
    flag_type_id = Database.get_1value(params["helper_query1"], "global")

    # read use flags and process each line
    IO.foreach(File.join(params["portage_home"], "profiles_v2", "use.desc")) do |line|
        # lets trim newlines
        line.chomp!()
        # skip comments or empty lines
        next if line.index('#') == 0 or line.empty?

        # lets get flag and desc
        match = pattern.match(line)

        Database.insert({
            "table" => params["table"],
            "data" => {
                "flag_name" => match[1],
                "flag_description" => match[2],
                "flag_type_id" => flag_type_id
            }
        })
    end

    sql_query = "SELECT COUNT(id) FROM #{params["table"]} WHERE flag_type_id=#{flag_type_id}"
    total_global_flags = Database.db().get_first_value(sql_query)
    sql_query = "SELECT COUNT(DISTINCT flag_name) FROM #{params["table"]} WHERE flag_type_id=#{flag_type_id}"
    unique_global_flags = Database.db().get_first_value(sql_query)

    if total_global_flags != unique_global_flags
        PLogger.error("Its very likely that global flags have duplicates")
    end
end

script.fill_table_X(method(:fill_table))

