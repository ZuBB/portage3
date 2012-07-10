#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
require 'script'

def get_data(params)
    # get all files from licenses dir
    (Dir[File.join(params["gentoo_tree_home"], 'licenses/*')].map { |item|
        File.file?(item) ?
            # TODO License names may contain
            #   [a-zA-Z0-9],
            #   _ (underscore),
            #   - (dash),
            #   . (dot)
            #   + (plus sign).
            # lets split flag and its description
            item.slice((params["gentoo_tree_home"] + 'licenses/').size + 1..-1) : nil
    }).compact
end

def process(params)
    Database.add_data4insert([params['value']])
end

script = Script.new({
    'script' => __FILE__,
    'thread_code' => method(:process),
    'sql_query' => 'INSERT INTO licences (name) VALUES (?);',
    'data_source' => method(:get_data),
})

