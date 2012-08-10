#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../../lib/common'))
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'utils'

# hash with options
options = {
    :search => nil,
    :searchdesc => nil
}

options.merge!(Utils::OPTIONS)

OptionParser.new do |opts|
    opts.banner = " Usage: equery option param\n"
    opts.separator " A script does same search as original equery application\n"

    opts.on("-b", "--belongs STRING", "list what package FILES belong to") do |value|
        options[:db_filename] = value
    end

    opts.on("-c", "--changes STRING", "list changelog entries for ATOM") do |value|
        options[:db_filename] = value
    end

    opts.on("-k", "--check STRING", "verify checksums and timestamps for PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-d", "--depends STRING", "list all packages directly depending on ATOM") do |value|
        options[:db_filename] = value
    end

    opts.on("-g", "--depgraph STRING", "display a tree of all dependencies for PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-f", "--files STRING", "list all files installed by PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-a", "--has STRING", "list all packages for matching ENVIRONMENT data stored in /var/db/pkg") do |value|
        options[:db_filename] = value
    end

    opts.on("-h", "--hasuse STRING", "list all packages that have USE flag") do |value|
        options[:db_filename] = value
    end

    opts.on("-y", "--keywords STRING", "display keywords for specified PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-l", "--list STRING", "list package matching PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-m", "--meta STRING", "display metadata about PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-s", "--size STRING", "display total size of all files owned by PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-u", "--uses STRING", "display USE flags for PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-w", "--which STRING", "print full path to ebuild for PKG") do |value|
        options[:db_filename] = value
    end

    #glsa(a)  - not implemented yet
    #stats(t)  - not implemented yet

    opts.on_tail("--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get true portage home
if options[:db_filename].nil?
    # get last created database
    options[:db_filename] = Utils.get_last_created_database(options)
end

