#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    # get all files from licenses dir
    Dir[File.join(params['tree_home'], 'licenses/*')].map() { |item|
        File.file?(item) ?
            # TODO License names may contain
            #   [a-zA-Z0-9],
            #   _ (underscore),
            #   - (dash),
            #   . (dot)
            #   + (plus sign).
            # lets split flag and its description
            item.slice((params['tree_home'] + 'licenses/').size + 1..-1) : nil
    } .compact
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => 'INSERT INTO licences (name) VALUES (?);'
})

