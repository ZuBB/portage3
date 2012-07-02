#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/09/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'common'))
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'portage'))
require 'optparse'
require 'database'
require 'plogger'
require 'ebuild'

options = {}
OptionParser.new do |opts|
    opts.banner = " Usage: purge_s3_data [options]\n"
    opts.separator " A script that purges outdated data from s3 bucket\n"

    opts.on("-d", "--database STRING", "Path to database") do |value|
        options[:db_filename] = value
    end

    # parsing 'quite' option if present
    opts.on("-f", "--ebuild-file STRING", "Path to ebuild") do |value|
        options[:filename] = value
    end

    # parsing 'quite' option if present
    opts.on("-C", "--category", "Show category") do |value|
        options[:category] = true
    end

    # parsing 'quite' option if present
    opts.on("-G", "--category-id", "Show category_id") do |value|
        options[:category_id] = true
    end

    # parsing 'quite' option if present
    opts.on("-P", "--package", "Show package") do |value|
        options[:package] = true
    end

    # parsing 'quite' option if present
    opts.on("-K", "--package-id", "Show package_id") do |value|
        options[:package_id] = true
    end

    # parsing 'quite' option if present
    opts.on("-V", "--version", "Show version") do |value|
        options[:version] = true
    end

    # parsing 'quite' option if present
    opts.on("-D", "--description", "Show description") do |value|
        options[:description] = true
    end

    # parsing 'quite' option if present
    opts.on("-H", "--homepage", "Show homepage") do |value|
        options[:homepage] = true
    end

    # parsing 'quite' option if present
    opts.on("-A", "--author", "Show author") do |value|
        options[:author] = true
    end

    # parsing 'quite' option if present
    opts.on("-T", "--mtime", "Show mtime") do |value|
        options[:mtime] = true
    end

    # parsing 'quite' option if present
    opts.on("-S", "--slot", "Show slot") do |value|
        options[:slot] = true
    end

    # parsing 'quite' option if present
    opts.on("-E", "--eapi", "Show eapi") do |value|
        options[:eapi] = true
    end

    # parsing 'quite' option if present
    opts.on("-I", "--eapi-id", "Show eapi_id") do |value|
        options[:eapi_id] = true
    end

    # parsing 'quite' option if present
    opts.on("-m", "--method STRING", "Use only specified parse method") do |value|
        options[:method] = value
    end

    # parsing 'quite' option if present
    opts.on("-U", "--use-flags", "Show use flags") do |value|
        options[:use] = value
    end

    # parsing 'quite' option if present
    opts.on("-2", "--2way-parse", "Use both parse methods") do |value|
        options[:parse2] = true
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

if options[:filename].nil? && ARGV[0].nil?
    puts "Ebuild file was not passed"
    exit(1)
end

file = options[:filename] || ARGV[0]
parts = file.split('/')
portage_index = parts.index('portage')
root_path = parts[1..portage_index].join('/')
category = parts[portage_index + 1]
package = parts[portage_index + 2]

# hash with data
data = {
    "portage_home" => '/' + root_path,
    "category" => category,
    "package" => package,
    "filename" => file,
    "method" => options[:method],
}

# hash with data
data = {
	"value" => {
		"parent_dir" => file[0..file.rindex('/') - 1],
		"value" => file[file.rindex('/') + 1..-1],
	},
    "method" => options[:method],
}

ebuild = Ebuild.new(data)

PLogger.init()
Database.init(data[:db_filename]) if options[:db_filename]

puts "category: #{ebuild.category}" if options[:category]
puts "category_id: #{ebuild.category_id}" if options[:category_id] && options[:db_filename]
puts "package: #{ebuild.package}" if options[:package]
puts "package_id: #{ebuild.package_id}" if options[:package_id] && options[:db_filename]
puts "description: #{ebuild.ebuild_description}" if options[:description]
puts "homepage: #{ebuild.ebuild_homepage}" if options[:homepage]
puts "mtime: #{ebuild.ebuild_mtime}" if options[:mtime]
puts "mauthor: #{ebuild.ebuild_author}" if options[:mauthor]
puts "version: #{ebuild.ebuild_version}" if options[:version]
puts "slot: #{ebuild.ebuild_slot}" if options[:slot]
puts "license: #{ebuild.ebuild_license}" if options[:license]
puts "eapi: #{ebuild.ebuild_eapi}" if options[:eapi]
puts "eapi_id: #{ebuild.ebuild_eapi_id}" if options[:eapi_id] && options[:db_filename]
puts "use flags: #{ebuild.ebuild_use_flags}" if options[:use]

