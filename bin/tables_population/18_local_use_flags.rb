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
    "helper_query1" => "SELECT id FROM use_flags_types WHERE flag_type=?",
    "helper_query2" => <<SQL
SELECT packages.id FROM packages, categories
WHERE
    categories.category_name=? and
    packages.package_name=? and
    packages.category_id=categories.id
SQL
})

def fill_table(params)
    # pattern for flag, its description and package
    pattern = Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?: - )(.*)")
    # flag type id
    flag_type_id = Database.get_1value(params["helper_query1"], "local")

    # read use flags and process each line
    IO.foreach(File.join(params["portage_home"], "profiles_v2", "use.local.desc")) do |line|
        # lets trim newlines
        line.chomp!()
        # skip comments or empty lines
        next if line.index('#') == 0 or line.empty?

        # lets get flag and desc
        match = pattern.match(line)

        Database.insert({
            "table" => params["table"],
            "data" => {
                "flag_name" => match[2],
                "flag_description" => match[3],
                "flag_type_id" => flag_type_id,
                "package_id" => Database.get_1value(
                    params["helper_query2"],
                    [match[1].split("/")[0], match[1].split("/")[1][0..-2]]
                )
            }
        })
    end
end

script.fill_table_X(method(:fill_table))

