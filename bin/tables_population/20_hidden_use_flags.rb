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
require 'parser'

script = Script.new({
    "table" => "use_flags",
    "script" => __FILE__,
    "helper_query1" => "SELECT id FROM use_flags_types WHERE flag_type=?"
})

def fill_table(params)
    # pattern for flag, its description and package
    pattern = Regexp.new("([\\w\\+\\-]+)(?:\\s-\\s)(.*)")
    # flag type id
    flag_type_id = Database.get_1value(params["helper_query1"], "expand_hidden")
    # items to construct ful path
    path_items = [params["portage_home"], "profiles_v2", "desc", "*desc"]
    # exceptions stuff
    exceptions_path_items = [params["portage_home"], "profiles_v2", "base", "make.defaults"]
    exceptions_file = File.join(*exceptions_path_items)
    exceptions = Parser.get_multi_line_ini_value(
        (IO.read(exceptions_file).to_a rescue []),
         "USE_EXPAND_HIDDEN"
    ).split(' ')

    # read use flags and process each line
    Dir.glob(File.join(*path_items)).each { |file|
        # get prefix for use flags in this file
        use_prefix = File.basename(file, ".desc")
        # skip if this file belongs to exceptions
        next unless exceptions.include?(use_prefix.upcase())
        # read use flags and process each line
        IO.foreach(file) do |line|
            # lets trim newlines
            line.chomp!()
            # skip comments or empty lines
            next if line.index('#') == 0 or line.empty?

            # lets get flag and desc
            match = pattern.match(line)
            # skip if we did not get a match
            next if match.nil?

            Database.insert({
                "table" => params["table"],
                "data" => {
                    "flag_name" => use_prefix + '_' + match[1],
                    "flag_description" => match[2],
                    "flag_type_id" => flag_type_id
                }
            })
        end
    }
end

script.fill_table_X(method(:fill_table))

