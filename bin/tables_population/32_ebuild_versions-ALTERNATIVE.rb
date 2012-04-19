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
    "sql_query" => "UPDATE ebuilds SET eix_version_order=?, portage_version_order=? WHERE id=?",
    # query for getting all versions of current package
    "helper_query1" => "SELECT id,version FROM ebuilds WHERE package_id=?",
    # query for getting all packages
    "helper_query2" => <<SQL
SELECT categories.category_name,packages.package_name,packages.id
from categories,packages
WHERE packages.category_id=categories.id;
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
    Database.db().execute(params["helper_query2"]) do |row|
        # empty array for versions only
        atom = "#{row[0]}/#{row[1]}"
        # empty array for versions only
        eix_versions = get_eix_versions(atom)
        # empty array for versions only
        portage_versions = get_portage_versions(atom)

        PLogger.info("Package #{atom}")

        # lets get them
        Database.db().execute(params["helper_query1"], [row[2]]) do |row2|
            eix_index = eix_versions.index { |version|
                version.end_with?(row2[1])
            }

            portage_index = portage_versions.index { |version|
                version.end_with?(row2[1])
            }

            unless eix_index.nil? && portage_index.nil?
                PLogger.info("Ebuild id: #{row2[0]}, index: #{eix_index + 1}")
                Database.insert({
                    "sql_query" => params["sql_query"],
                    "values" => [eix_index + 1, portage_index + 1, row2[0]]
                })
            else
                PLogger.info("eix versions #{eix_versions.join(', ')}")
                PLogger.info("portage versions #{portage_versions.join(', ')}")
                PLogger.warn("Version #{row2[1]} - 'cache miss'")
                PLogger.warn("eix_index: #{eix_index}")
                PLogger.warn("portage_index: #{portage_index}")
            end
        end
    end
end

script.fill_table_X(method(:fill_table))

