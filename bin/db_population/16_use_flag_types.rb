#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/04/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

USEFLAG_TYPES = [
    [
        'global',
        'Global USE Flags (present in at least 5 packages)',
        'profiles/use.desc'
    ],
    [
        'local',
        'Local USE Flags (present in the package\'s metadata.xml)',
        'profiles/use.local.desc'
    ],
    [
        'expand',
        'Env vars to expand into USE vars',
        'profiles/desc/*'
    ],
    [
        'expand_hidden',
        'variables whose contents are not shown in package manager output',
        'profiles/base/make.defaults'
    ]
]

script = Script.new({
    'data_source' => Proc.new { USEFLAG_TYPES },
    'sql_query' => <<-SQL
        INSERT INTO use_flag_types
        (flag_type, description, source)
        VALUES (?, ?, ?);
    SQL
})

