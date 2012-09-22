#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
require_relative 'envsetup'
require 'emerge-search'

# hash with options
options = {
    'search' => nil,
    'searchdesc' => nil,
    'db_filename' => nil
}

options.merge!(Utils::OPTIONS)

OptionParser.new do |opts|
    opts.banner = " Usage: emerge [options] [params]\n"
    opts.separator " A script does same emerge application\n"

    opts.on('-f', '--db-filename STRING', 'Path to custom database') do |value|
        options['db_filename'] = value
    end

    opts.on('-s', '--search PATTERN', "Does same as 'emerge -s PATTERN'\n"\
        "#{' '*38}Note: use '/' as category_pattern/package_pattern separator") do |value|
            options['search'] = value
    end

    opts.on('-S', '--searchdesc STRING', "Does same as 'emerge -S PATTERN'") do |value|
        options['searchdesc'] = value
    end

    opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
    end
end.parse!

options['db_filename'] ||= Utils.get_database
Database.init(options['db_filename'])

if options['search']
    EmergeSearch.search_by_names(options['search'])
elsif options['searchdesc']
    EmergeSearch.search_by_names8desc(options['searchdesc'])
end

Database.close

