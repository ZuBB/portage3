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

def get_description(portage_home, category)
    metadata_path = File.join(portage_home, category, "metadata.xml")
    description = '0_DESC_NF'

    if File.exists?(metadata_path) && File.readable?(metadata_path)
        xml_doc = Nokogiri::XML(IO.read(metadata_path))
        # TODO hardcoded 'en'
        description_node = xml_doc.xpath('//longdescription[@lang="en"]')
        description = description_node.inner_text.gsub(/\s+/, ' ')
    end

    return description
end

def insert_category(database, portage_home, category)
    database.execute(
        "INSERT INTO categories (category_name, description) VALUES (?, ?);",
        category,
        get_description(portage_home, category)
    )
end

def fill_table(database, params)
    walk_through_categories({
        :portage_home => params[:portage_home],
        :block => method(:insert_category),
        :database => database
    })
end

# TODO: check if all dependant tables are filled
#File.basename(__FILE__).match(/^\d\d_([a-z]+)\.rb$/)[1].to_s,

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)

