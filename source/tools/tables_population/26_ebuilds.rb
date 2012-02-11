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
require 'time'

# hash with options
options = Hash.new.merge!(OPTIONS)
# hash with options
SQL_QUERY = <<SQL
INSERT INTO ebuilds
(package_id, version, mtime, mauthor, eapi_id, slot, license)
VALUES (?, ?, ?, ?, ?, ?, ?);
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

def get_eapi_id(database, ebuild_obj)
    eapi = ebuild_obj["eapi"] == '0_EAPI_NF' ? 0 : ebuild_obj["eapi"]
    database.get_first_value("SELECT id FROM eapis WHERE eapi_version=?", eapi)
end

def store_real_eapi(database, ebuild_obj)
    sql_query = "INSERT INTO _note_eapi_0_NF (eapi_version) VALUES ?;"
    database.execute(sql_query, ebuild_obj['ebuild_id'])
end

def parse_ebuild(database, package_id, ebuild_filename)
    ebuild_obj = {"package_id" => package_id}
    ebuild_text = IO.read(ebuild_filename).to_a rescue []

    ebuild_obj["eapi"] = get_eapi(ebuild_text)
    ebuild_obj["slot"] = get_slot(ebuild_text)
    ebuild_obj["mtime"] = get_ebuild_mtime(ebuild_text)
    ebuild_obj["author"] = get_ebuild_author(ebuild_text)
    ebuild_obj["license"] = get_license(ebuild_text)
    ebuild_obj["version"] = get_ebuild_version(ebuild_text)

    ebuild_obj["real_eapi"] = get_eapi_id(database, ebuild_obj)
    ebuild_obj["eapi_id"], ebuild_obj["real_eapi"] =
        ebuild_obj["real_eapi"], ebuild_obj["eapi_id"]

    database.execute(
        SQL_QUERY,
        ebuild_obj["package_id"],
        ebuild_obj["version"],
        ebuild_obj["mtime"],
        ebuild_obj["author"],
        ebuild_obj["eapi_id"],
        # TODO
        0, #ebuild_obj["slot"],
        ebuild_obj["license"]
    )

    ebuild_obj['ebuild_id'] = get_last_inserted_id(database)
    #store_real_eapi(database, ebuild_obj)
end

def category_block(params)
    walk_through_packages({:block2 => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    ebuilds = Dir.glob(File.join(params[:item_path], '*.ebuild')).to_a
    ebuilds.sort! do |ebuild_a, ebuild_b|
        comparison_result = nil
        a_parts = ebuild_a.match(ATOM_VERSION).to_a.compact.last.split(/[\.\-_]/)
        b_parts = ebuild_b.match(ATOM_VERSION).to_a.compact.last.split(/[\.\-_]/)
        a_parts.each_index { |index|
            a_part_raw = a_parts[index] rescue ''
            b_part_raw = b_parts[index] rescue ''

            if a_part_raw && b_part_raw.nil?
                comparison_result = 1
                break
            end

            a_part = a_part_raw.to_i
            b_part = b_part_raw.to_i

            is_a_num = a_part.to_s == a_part_raw
            is_b_num = b_part.to_s == b_part_raw

            if a_part_raw == b_part_raw
                next
            elsif is_a_num == is_b_num && is_b_num == true
                comparison_result = a_part > b_part ? 1 : -1
            elsif is_a_num == is_b_num && is_b_num == false && a_part_raw.size == b_part_raw.size
                comparison_result = a_part_raw > b_part_raw ? 1 : -1
            else
                a_sub_part = a_part_raw.scan(/\d+|[a-z]+/)
                b_sub_part = b_part_raw.scan(/\d+|[a-z]+/)

                if a_sub_part[0] == b_sub_part[0]
                    if a_sub_part[1] && b_sub_part[1].nil?
                        comparison_result = 1
                    elsif b_sub_part[1] && a_sub_part[1].nil?
                        comparison_result = -1
                    elsif a_sub_part[1].to_i > b_sub_part[1].to_i
                        comparison_result = 1
                    else
                        comparison_result = -1
                    end
                else
                    comparison_result = a_sub_part[0] > b_sub_part[0] ? 1 : -1
                end
            end

            break unless comparison_result.nil?
        }

        if comparison_result.nil?
            comparison_result = a_parts.size > b_parts.size ? 1 : -1
        end

        comparison_result
    end

    ebuilds.each do |ebuild|
        parse_ebuild(
            params[:database],
            get_package_id(
                params[:database],
                params[:category],
                params[:package]
            ),
            ebuild
        )
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
