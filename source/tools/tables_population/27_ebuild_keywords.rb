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
require 'sqlite3'
require 'tools'

# hash with options
options = Hash.new.merge!(OPTIONS)
# sql
SQL_QUERY = <<SQL
INSERT INTO package_keywords
(package_id, version, keyword_id, arch_id, source_id)
VALUES (
    ?,
    ?,
    (SELECT id FROM keywords WHERE keyword=?),
    (SELECT id FROM arches WHERE arch_name=?),
    (SELECT id FROM sources WHERE source='ebuilds')
)
SQL

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

def get_ebuild_version(ebuild_text)
    regexp = Regexp.new("-(\\d.*)\\.ebuild,v")
    result = get_value_from_cvs_header(ebuild_text, regexp)
    return result || '0_VERSION_NF'
end

def get_ebuild_mtime(ebuild_text)
    regexp = Regexp.new("\\d{4}\\/\\d\\d\\/\\d\\d \\d\\d:\\d\\d:\\d\\d")
    result = get_value_from_cvs_header(ebuild_text, regexp)
    return (Time.parse(result).to_i rescue '0_TIME_NF')
end

def get_ebuild_author(ebuild_text)
    regexp = Regexp.new(":\\d\\d ([\\w_\\-\\.]+) Exp \\$$")
    result = get_value_from_cvs_header(ebuild_text, regexp)
    return result || '0_AUTHOR_NF'
end

def get_ebuild_description(ebuild_text)
    get_single_line_ini_value(ebuild_text, 'DESCRIPTION') || '0_DESC_NF'
end

def get_ebuild_keywords(ebuild_text)
    get_single_line_ini_value(ebuild_text, 'KEYWORDS') || '0_KEYWORDS_NF'
end

def get_ebuild_homepage(ebuild_text)
    get_single_line_ini_value(ebuild_text, 'HOMEPAGE') || '0_WWWPAGE_NF'
end

def get_eapi(ebuild_text)
    # http://goo.gl/DaruK || eselect-python-99999999
    # ./media-gfx/dawn/dawn-3.88a.ebuild
    # http://devmanual.gentoo.org/ebuild-writing/eapi/index.html
    # NF is 'not found'. means we din not find eapi declaration here
    get_single_line_ini_value(ebuild_text, 'EAPI').to_i || '0_EAPI_NF'
end

def get_slot(ebuild_text)
    # app-admin/phpsyslogng/phpsyslogng-2.8-r1.ebuild
    # NSP is 'no slot present'. means we din not find eapi declaration here
    # http://devmanual.gentoo.org/general-concepts/slotting/index.html
    get_single_line_ini_value(ebuild_text, 'SLOT').to_i || '0_SLOT_NF'
end

def get_license(ebuild_text)
    # https://bugs.gentoo.org/show_bug.cgi?id=398575
    get_single_line_ini_value(ebuild_text, 'LICENSE') || '0_LICENSE_NF'
end

def store_ebuild_keywords(database, ebuild_obj)
    keywords, ebuild_obj["keywords"] = ebuild_obj["keywords"], []
    if keywords == "0_KEYWORDS_NF"
        ebuild_obj["keywords_real"] = '0_KEYWORDS_NF'
        ebuild_obj["keywords"] << { "arch" => '*', "sign" => '?' }
        keywords = ""
    elsif keywords.include?("-*") && keywords.size > 2
        keywords.sub!('-*', '')
        ebuild_obj["keywords"] << { "arch" => '*', "sign" => '-' }
    end

    keywords.split().each { |keyword|
        ebuild_obj["keywords"] << {
            "sign" => (keyword.match(/^[~\-\?]/).to_s rescue ''),
            "arch" => keyword.sub(/^[~\-\?]/, '')
        }
    }

    ebuild_obj["keywords"].each do |keyword|
        status, arch = 'stable', keyword["arch"]
        status = 'unstable' if keyword["sign"] == '~'
        status = 'not work' if keyword["sign"] == '-'
        status = 'not known' if keyword["sign"] == '?'

        database.execute(
            SQL_QUERY,
            ebuild_obj['package_id'],
            ebuild_obj['ebuild_id'],
            status,
            arch
        )
    end
end

def parse_ebuild(database, package_id, ebuild_filename)
    ebuild_obj = {"package_id" => package_id}
    ebuild_text = IO.read(ebuild_filename).to_a rescue []

    ebuild_obj["version"] = get_ebuild_version(ebuild_text)
    ebuild_obj["keywords"] = get_ebuild_keywords(ebuild_text)
    ebuild_obj['ebuild_id'] = database.get_first_value(
        "SELECT id FROM ebuilds WHERE package_id=? AND version=?",
        ebuild_obj["package_id"],
        ebuild_obj["version"]
    )

    return ebuild_obj
end

def category_block(params)
    walk_through_packages({:block2 => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    Dir.glob(File.join(params[:item_path], '*.ebuild')).sort.each do |ebuild|
        ebuild_obj = parse_ebuild(
            params[:database],
            get_package_id(
                params[:database],
                params[:category],
                params[:package]
            ),
            ebuild
        )
        store_ebuild_keywords(params[:database], ebuild_obj)
    end
end

def fill_table(params)
    walk_through_categories(
        {:block1 => method(:category_block)}.merge!(params)
    )
end

fill_table_X(
    options[:db_filename],
    method(:fill_table),
    {:portage_home => portage_home}
)
