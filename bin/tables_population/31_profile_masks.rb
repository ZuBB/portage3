#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'fileutils'
require 'script'

script = Script.new({
    "script" => __FILE__,
    "sql_query" => <<SQL
INSERT INTO package_masks
(package_id, version, arch_id, source_id, mask_state_id)
VALUES (
    ?, ?, ?, ?,
    (SELECT id FROM mask_states WHERE mask_state=?)
)
SQL
})

def parse_line(line)
    result = {}

    # take care about leading '-'
    # it means this atom/package should treated as unmasked
    result["mask_state"] = line.index('-') == 0 ? 'unmasked' : 'masked'

    # take care about leading ~
    # it means match any subrevision of the specified base version.
    if line.index('~') == 0
        line.sub!(/^~/, '')

        if line.include?(':')
            line.sub!(":", "*:") unless line.include?('*:')
        else
            line << '*' unless line.end_with?('*')
        end
    end

    # version restrictions
    unless line.match(Utils::RESTRICTION).nil?
        result["version_restrictions"] = line.match(Utils::RESTRICTION).to_s
        line.sub!(Utils::RESTRICTION, '')
    end

    # deal with versions
    version_match = line.match(Utils::ATOM_VERSION)
    version_match = version_match.to_a.compact unless version_match.nil?
    version_match = nil if version_match.size == 1 && version_match.to_s.empty?

    unless version_match.nil?
        result["version"] = version_match.last
        result["version"] << '*' if version_match.size == 2

        if result["version_restrictions"].nil?
            result["version_restrictions"] = '='
        end

        line.sub!(Utils::ATOM_VERSION, '')
    else
        result["version"] = '*'
        result["version_restrictions"] = '='
    end

    match = line.split('/')
    result['category'] = match[0]
    result['package'] = match[1]

    return result
end

def get_source_id(file)
    Database.get_1value(
        "SELECT id FROM sources WHERE source=?",
        [File.dirname(file) + '/']
    )
end

def get_arch_id(file)
    dir = File.dirname(file) + '/'

    if dir == 'base/'
        Database.db().execute("SELECT id FROM arches").flatten
    elsif dir.count('/') == 2
        sql_query = <<SQL
SELECT id
FROM arches
WHERE architecture_id=
    (SELECT id from architectures where architecture=?)
SQL
        Database.db().execute(sql_query, dir.split('/')[1])
    else
        sql_query = <<SQL
SELECT id
FROM arches
WHERE
    architecture_id=(SELECT id FROM architectures WHERe architecture=?) AND
    platform_id=(SELECT id FROM platforms WHERe platform_name=?)
SQL
        Database.db().execute(sql_query, dir.split('/')[1], dir.split('/')[2]).flatten
    end
end

def fill_table(params)
    filepath = File.join(params["portage_home"], "profiles_v2")
    FileUtils.cd(filepath)

    # walk through all use flags in that file
    Dir['**/package.mask'].each do |filename|
        # skip dirs that has 'deprecated' file in it
        next if File.exist?(File.join(
            filepath, filename.sub('package.mask', 'deprecated')
        ))

        File.open(filename, "r") do |infile|
            while (line = infile.gets)
                # skip comments
                next if line.index('#') == 0
                # skip empty lines
                next if line.chomp!().empty?

                result = parse_line(line)

                result['package_id'] = Database.get_1value(
                    "SELECT packages.id FROM packages, categories WHERE categories.category_name=? and packages.package_name=? and packages.category_id = categories.id",
                     [result['category'], result['package']]
                )

                if result['package_id'].nil?
                    # TODO
                    next 
                end

                result_set = nil

                if result["version"] == '*'
                    local_query = "SELECT id FROM ebuilds WHERE package_id=?"
                    result_set = Database.db().execute(local_query, result["package_id"]).flatten
                elsif result["version_restrictions"] == '=' && result["version"].end_with?('*')
                    version_like = result["version"].sub('*', '')
                    local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version like '#{version_like}%'"
                    result_set = Database.db().execute(local_query, result["package_id"]).flatten
                else
                    local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version#{result["version_restrictions"]}?"
                    result_set = Database.db().execute(local_query, result["package_id"], result["version"]).flatten
                end

                result["arch"] = get_arch_id(filename)

                if result_set.size() > 0
                    result_set.each { |version|
                        result['arch'].each { |arch|
                            Database.insert({
                                "sql_query" => params["sql_query"],
                                "values" => [
                                    result['package_id'],
                                    version,
                                    arch,
                                    get_source_id(filename),
                                    result["mask_state"]
                            ]
                            })
                        }
                    }
                else
                    # means =category/atom-version that
                    # already does not exist in portage
                    # TODO handles this
                end
            end
        end
    end
end

script.fill_table_X(method(:fill_table))
