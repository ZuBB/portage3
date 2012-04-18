#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "script" => __FILE__,
    # query for getting all versions of current package
    "sql_query" => "UPDATE ebuilds SET version_order=? WHERE id=?",
    # query for getting all versions of current package
    "helper_query2" => "SELECT id,version FROM ebuilds WHERE package_id=?",
    # query for getting all packages
    "helper_query1" => <<SQL
SELECT c.category_name, p.package_name, p.id
from categories c, packages p
WHERE p.category_id=c.id;
SQL
})

def get_eix_versions(atom)
    versions_line = %x[eix -x --end #{atom} | grep 'Available versions']

    # drop wording at start
    versions_line.sub!(/^\s*Available versions:/, "")

    # drop use flags
    versions_line.sub!(/\{[^\}]+\}\s*$/, "") if versions_line.match(/\}\s*$/)

    # get versions and make it looks nice
    versions_line.split(' ').map! { |version|
        version.sub!(/!.+/, '')  if version.match(/!.+/)
        version.sub!(/\([^\)]+\)\s*$/, '') if version.match(/\)\s*$/)
        version.sub!(/\+i$/, '') if version.match(/\+i$/)
        version.sub!(/\+v$/, '') if version.match(/\+v$/)
        version
    }
end

def get_portage_versions(atom)
    versions = []
    # empty array for versions only
    %x[../list_package_ebuilds.py #{atom}].split("\n").each { |line|
        versions << line[atom.size + 1..-1]
    }

    return versions
end

def fill_table(params)
    # lets walk through all packages
    Database.db().execute(params["helper_query1"]) do |package_row|
        # get atom naem
        atom = "#{package_row[0]}/#{package_row[1]}"
        # get versions sorted by eix
        eix_versions = get_eix_versions(atom)

        PLogger.info("Package #{atom}")

        # lets get them
        Database.db().execute(params["helper_query2"], [package_row[2]]) do |ebuild_row|
            eix_index = eix_versions.index { |version|
                version.end_with?(ebuild_row[1])
            }

            unless eix_index.nil?
                PLogger.info("Ebuild id: #{ebuild_row[0]}, index: #{eix_index + 1}")
                Database.insert({
                    "sql_query" => params["sql_query"],
                    "values" => [eix_index + 1, ebuild_row[0]]
                })
            else
                PLogger.warn("Version #{ebuild_row[1]} - 'cache miss'")
                PLogger.info("eix versions #{eix_versions.join(', ')}")
            end
        end
    end
end

script.fill_table_X(method(:fill_table))

