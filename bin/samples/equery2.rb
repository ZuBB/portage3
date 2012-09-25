#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
require_relative 'envsetup'
require 'equery'

# hash with options
options = {'db_filename' => nil}

cli = OptionParser.new do |opts|
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
        options['size'] = true
        options['atom'] = value
    end

    opts.on("-u", "--uses STRING", "display USE flags for PKG") do |value|
        options[:db_filename] = value
    end

    opts.on("-w", "--which STRING", "print full path to ebuild for PKG") do |value|
        options['which'] = true
        options['atom'] = value
    end

    opts.on_tail("--help", "Show this message") do
        puts opts
        exit
    end
end

cli.parse!

unless options.keys.reject { |i| i == 'atom' }.any? { |i| options[i] }
	print cli.help
	exit
end

options['db_filename'] ||= Utils.get_database
Database.init(options['db_filename'])

atom       = Equery.get_atom_specs(options['atom'])
package_id = Equery.get_package_id(atom)
ebuild_id  = Equery.get_ebuild_id(atom, package_id)

output = case
         when options['which']
             Equery::EqueryWhich.get_ebuild_path(ebuild_id)
         when options['size']
             Equery::EquerySize.get_package_size(package_id)
         else
             puts "TODO"
         end

puts output
