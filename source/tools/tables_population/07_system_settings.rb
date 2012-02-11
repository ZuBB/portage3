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
require 'time'

# hash with options
options = Hash.new.merge!(OPTIONS)
# hash with options
SQL_QUERY = "INSERT INTO system_settings (option, value) VALUES (?, ?);"

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

def get_accept_keywords(ebuild_text)
    get_single_line_ini_value(ebuild_text, 'ACCEPT_KEYWORDS') || '0_AK_NF'
end

def fill_table(params)
    make_conf = IO.read('/etc/make.conf').to_a rescue []
    accept_keywords = get_accept_keywords(make_conf)
    keyword_name = accept_keywords.index('~') == 0 ? 'unstable' : 'stable'
    arch_name = accept_keywords.sub(/^~/, '')

    params[:database].execute(
        SQL_QUERY,
        'arch',
        params[:database].get_first_value(
            "SELECT id FROM arches WHERE arch_name=?",
            arch_name
        )
    )

    params[:database].execute(
        SQL_QUERY,
        'keyword',
        params[:database].get_first_value(
            "SELECT id FROM keywords WHERE keyword=?",
            keyword_name
        )
    )
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {}
)
