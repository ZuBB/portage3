#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
require 'script'

USEFLAG_TYPES = [
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

def get_data(params)
    USEFLAG_TYPES
end

def process(params)
    Database.insert({
        "table" => params["table"],
        "data" => {
            "flag_type" => params["value"]["type"],
            "description" => params["value"]["description"],
            "source" => params["value"]["source"]
        }
    })
end

script = Script.new({
    "script" => __FILE__,
    "table" => "use_flags_types",
    'data_source' => method(:get_data),
    'thread_code' => method(:process)
})

