#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

TYPES = [
    {
        "type" => "global",
        "description" => "Global USE Flags (present in at least 5 packages)",
        "source" => "profiles/use.desc"
    },
    {
        "type" => "local",
        "description" => "Local USE Flags (present in the package's metadata.xml)",
        "source" => "profiles/use.local.desc"
    },
    {
        "type" => "expand",
        "description" => "Env vars to expand into USE vars",
        "source" => "profiles/desc/*"
    },
    {
        "type" => "expand_hidden",
        "description" => "variables whose contents are not shown in package manager output",
        "source" => "profiles/base/make.defaults"
    }
]

script = Script.new({
    "table" => "use_flags_types",
    "script" => __FILE__
})

def fill_table(params)
    TYPES.each do |item|
        Database.insert({
            "table" => params["table"],
            "data" => {
                "flag_type" => item["type"],
                "description" => item["description"],
                "source" => item["source"]
            }
        })
    end
end

script.fill_table_X(method(:fill_table))

