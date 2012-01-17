#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'optparse'
require 'rubygems'
require 'nokogiri'
require 'sqlite3'
require 'tools'

# hash with options
options = Hash.new.merge!(OPTIONS)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: purge_s3_data [options]\n"
    opts.separator " A script that purges outdated data from s3 bucket\n"

    opts.on("-f", "--database-file STRING",
            "Path where new database file will be created") do |value|
        # TODO check if path id valid
        options[:db_filename] = value
    end

    #TODO do we need a setting `:root` option here?
    # parsing 'quite' option if present
    opts.on("-q", "--quiet", "Quiet mode") do |value|
        options[:quiet] = true
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get true portage home
portage_home = get_full_tree_path(options)
if options[:db_filename].nil?
    # get last created database
    options[:db_filename] = get_last_created_database(options)
end

def get_ebuild_description(ebuild_text)
    return get_single_line_ini_value(ebuild_text, 'DESCRIPTION') || '0_DESC_NF'
end

def get_ebuild_homepage(ebuild_text)
    return get_single_line_ini_value(ebuild_text, 'HOMEPAGE') || '0_WWWPAGE_NF'
end

def category_block(params)
    category_id = get_category_id(params[:database], params[:category])

    walk_through_packages({
        :portage_home => params[:portage_home],
        :database => params[:database],
        :category => params[:category],
        :category_id => category_id,
        :block => method(:packages_block),
    })
end

def packages_block(params)
    # lets get full path for this item
    item_path = File.join(params[:portage_home], params[:category], params[:package])
    # skip if it is a ..
    next if ['.', '..'].include?(params[:package])
    # skip if it is a ..
    next if File.file?(item_path)

    # get content of the last ebuild for this package
    ebuild_filename_pattern = File.join(item_path, '*.ebuild')
    ebuild_filename = Dir.glob(ebuild_filename_pattern).sort.last
    ebuild_text = IO.read(ebuild_filename).to_a

    description = get_ebuild_description(ebuild_text)
    homepage = get_ebuild_homepage(ebuild_text)

    sql_query = <<SQL
    INSERT INTO packages
    (category_id, package_name, description, homepage)
    VALUES (?, ?, ?, ?);
SQL
    params[:database].execute(sql_query, params[:category_id], params[:package], description, homepage)
end

def fill_table(params)
    walk_through_categories(
        {:block => method(:category_block)}.merge!(params)
    )
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)

