#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/01/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "script" => __FILE__,
    "sql_query" => <<SQL
INSERT INTO package_masks
(package_id, version, arch_id, mask_state_id, source_id)
VALUES (?, ?, ?, ?, ?)
SQL
})

def parse_line(line)
    result = {}

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

def get_arch_id()
    return Database.get_1value(
        "SELECT value FROM system_settings WHERE param=?;", ['arch']
    )
end

def parse_file(params, file_content, mask_state)
    file_content.each { |line|
        # skip comments
        next if line.index('#') == 0
        # skip empty lines
        next if line.chomp!().empty?

        result = parse_line(line)

        result['package_id'] = Database.get_1value(
            "\
            SELECT packages.id \
            FROM packages, categories \
            WHERE \
            categories.category_name=? and \
            packages.package_name=? and \
            packages.category_id = categories.id",
            [result['category'], result['package']]
        )

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

        result["arch"] = get_arch_id()

        if result_set.size() > 0
            result_set.each { |version|
                Database.insert({
                    "sql_query" => params["sql_query"],
                    "values" => [
                        result['package_id'],
                        version,
                        result["arch"],
                        mask_state,
                        Database.get_1value(
                            "SELECT id FROM sources WHERE source=?",
                            ['/etc/portage/']
                        )
                    ]
                })
            }
        else
            # means =category/atom-version that
            # already does not exist in portage
            # TODO handles this
        end
    }
end

def fill_table(params)
    filename = File.join(Utils::OPTIONS["settings_folder"], "package.mask")
    parse_file(
        params,
        (IO.read(filename).to_a rescue []),
        Database.get_1value(
            "SELECT id FROM mask_states WHERE mask_state=?", ['masked']
        )
    )

    filename = File.join(Utils::OPTIONS["settings_folder"], "package.unmask")
    parse_file(
        params,
        (IO.read(filename).to_a rescue []),
        Database.get_1value(
            "SELECT id FROM mask_states WHERE mask_state=?", ['unmasked']
        )
    )
end

script.fill_table_X(method(:fill_table))
