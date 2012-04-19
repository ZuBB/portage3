#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "script" => __FILE__,
    "sql_query" => <<SQL
INSERT INTO package_keywords
(package_id, ebuild_id, keyword_id, arch_id, source_id)
VALUES (
    ?, ?, ?, ?,
    (SELECT id FROM sources WHERE source='/etc/portage/')
);
SQL
})

def parse_line(line)
    result = {}

    if line.include?(' ')
        atom = line.split()[0]
        arch = line.split()[1]
        if arch == '**'
            result["arch"] = Database.db().execute("SELECT id FROM arches;").flatten
            atom << '*' unless atom.end_with?('*')
        end
    else
        atom = line
    end

    # take care about leading ~
    # it means match any subversion of the specified base version.
    if atom.index('~') == 0
        atom.sub!(/^~/, '')

        if atom.include?(':')
            atom.sub!(":", "*:") unless atom.include?('*:')
        else
            atom << '*' unless atom.end_with?('*')
        end
    end

    # version restrictions
    unless atom.match(Utils::RESTRICTION).nil?
        result["version_restrictions"] = atom.match(Utils::RESTRICTION).to_s
        atom.sub!(Utils::RESTRICTION, '')
    end

    # deal with versions
    version_match = atom.match(Utils::ATOM_VERSION)
    version_match = version_match.to_a.compact unless version_match.nil?
    version_match = nil if version_match.size == 1 && version_match.to_s.empty?

    unless version_match.nil?
        version = version_match.last
        version << '*' if version_match.size == 2 && !atom.end_with?('*')

        if result["version_restrictions"].nil?
            result["version_restrictions"] = '='
        end

        result['version'] =  version

        atom.sub!(Utils::ATOM_VERSION, '')
    else
        result["version"] = '*'
        result["version_restrictions"] = '='
    end

    match = atom.split('/')
    result['category'] = match[0]
    result['package'] = match[1]
    if result["arch"].nil?
        result["arch"] = Database.db().execute(
            "SELECT value FROM system_settings WHERE param='arch';"
        )
    end
    result["keyword"] = Database.db().get_first_value(
        "SELECT value FROM system_settings WHERE param='keyword';"
    )

    return result
end

def fill_table(params)
    filename = File.join(Utils::OPTIONS["settings_folder"], "package.keywords")
    file_content = IO.read(filename).to_a# rescue []

    file_content.each { |line|
        # skip comments
        next if line.index('#') == 0
        # trim '\n'
        line.chomp!()
        # skip empty lines
        next if line.empty?()

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

        if result_set.size() > 0
            result_set.each { |version|
                result['arch'].each { |arch|
                    Database.insert({
                        "sql_query" => params["sql_query"],
                        "values" => [
                            result['package_id'],
                            version,
                            result["keyword"],
                            arch
                        ]
                    })
                }
            }
        else
            # means =category/atom-version that
            # already does not exist in portage
            # TODO handles this
        end
    }
end

script.fill_table_X(method(:fill_table))

