#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 04/09/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../..', 'lib', 'common'))
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../..', 'lib', 'portage'))
require 'optparse'
require 'database'
require 'plogger'
require 'ebuild'

options = {}
OptionParser.new do |opts|
    opts.banner = " Usage: ebuild-probe.rb [options] ebuild path|atom\n"
    opts.separator " A script shows ebuild's props\n"

    opts.on("-d", "--database STRING", "Path to database") do |value|
        options[:db_filename] = value
    end

    opts.on("-f", "--ebuild-file STRING", "Path to ebuild") do |value|
        options[:filename] = value
    end

    opts.on("-C", "--category-id", "Show category_id") do |value|
        options[:category_id] = true
    end

    opts.on("-P", "--package-id", "Show package_id") do |value|
        options[:package_id] = true
    end

    opts.on("-D", "--description", "Show description") do |value|
        options[:description] = true
    end

    opts.on("-H", "--homepage", "Show homepage") do |value|
        options[:homepage] = true
    end

    opts.on("-A", "--author", "Show author") do |value|
        options[:author] = true
    end

    opts.on("-T", "--mtime", "Show mtime") do |value|
        options[:mtime] = true
    end

    opts.on("-S", "--slot", "Show slot") do |value|
        options[:slot] = true
    end

    opts.on("-E", "--eapi", "Show eapi") do |value|
        options[:eapi] = true
    end

    opts.on("-K", "--keywords", "Show keywords") do |value|
        options[:keywords] = true
    end

    opts.on("-L", "--license", "Show license") do |value|
        options[:license] = true
    end

    opts.on("-U", "--use-flags", "Show use flags") do |value|
        options[:use] = true
    end

    opts.on("-m", "--method STRING", "Use only specified parse method") do |value|
        options[:method] = value
    end

    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

if options[:filename].nil? && ARGV[0].nil?
    puts "Ebuild file/atom was not specified"
    exit(1)
end

#params = ["gentoo", "/dev/shm", "portage", "app-crypt", "md4sum", "0.02.03"]
params = ["gentoo"]
file = options[:filename] || ARGV[0]
parts = file.split('/')
portage_index = parts.index('portage')
params << parts[1..portage_index].join('/')
params << parts[portage_index]
params << parts[portage_index + 1]
params << parts[portage_index + 2]
params << parts.last[params.last.size + 1..-8]

ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))

#PLogger.init()
Database.init(data[:db_filename]) if options[:db_filename]

puts "category: #{ebuild.category}"
puts "category_id: #{ebuild.category_id}" if options[:category_id] && options[:db_filename]
puts "package: #{ebuild.package}"
puts "package_id: #{ebuild.package_id}" if options[:package_id] && options[:db_filename]
puts "version: #{ebuild.ebuild_version}"
puts "description: #{ebuild.ebuild_description}" if options[:description]
puts "homepage: #{ebuild.ebuild_homepage}" if options[:homepage]
puts "mtime: #{ebuild.ebuild_mtime}" if options[:mtime]
puts "mauthor: #{ebuild.ebuild_author}" if options[:author]
puts "slot: #{ebuild.ebuild_slot}" if options[:slot]
puts "license: #{ebuild.ebuild_license}" if options[:license]
puts "eapi: #{ebuild.ebuild_eapi}" if options[:eapi]
puts "keywords: #{ebuild.ebuild_keywords}" if options[:keywords]
puts "use flags: #{ebuild.ebuild_use_flags}" if options[:use]

