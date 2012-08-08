#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []

    filename = File.join(Utils.get_portage_settings_home, 'package.keywords')
    # TODO we do not support 'package.keywords' as directories for now
    if !File.exist?(filename) || File.directory?(filename)
        return results
    end

    IO.foreach(filename) do |line|
        next if line.index('#') == 0
        next if line.chomp!().empty?()

        results << line
    end

    return results
end

def parse_line(line)
    result = {}

    if line.include?(' ')
        atom = line.split()[0]
        arch = line.split()[1]
        if arch == '**'
            result['arch'] = Database.select('SELECT id FROM arches;').flatten
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
            atom.sub!(':', '*:') unless atom.include?('*:')
        else
            atom << '*' unless atom.end_with?('*')
        end
    end

    # version restrictions
    unless atom.match(Utils::RESTRICTION).nil?
        result['version_restrictions'] = atom.match(Utils::RESTRICTION).to_s
        atom.sub!(Utils::RESTRICTION, '')
    end

    # deal with versions
    version_match = atom.match(Utils::ATOM_VERSION)
    version_match = version_match.to_a.compact unless version_match.nil?
    version_match = nil if version_match.size == 1 && version_match.to_s.empty?

    unless version_match.nil?
        version = version_match.last
        version << '*' if version_match.size == 2 && !atom.end_with?('*')

        if result['version_restrictions'].nil?
            result['version_restrictions'] = '='
        end

        result['version'] =  version

        atom.sub!(Utils::ATOM_VERSION, '')
    else
        result['version'] = '*'
        result['version_restrictions'] = '='
    end

    match = atom.split('/')
    result['category'] = match[0]
    result['package'] = match[1]
    if result['arch'].nil?
        result['arch'] = Database.select(
            'SELECT value FROM system_settings WHERE param=\'arch\';'
        )
    end
    result['keyword'] = Database.get_1value(
        'SELECT value FROM system_settings WHERE param=\'keyword\';'
    )

    return result
end

class Script
    def process(params)
        result = parse_line(params)
        result['package_id'] = Database.select(
            "SELECT p.id "\
            "FROM packages p "\
            "JOIN categories c on p.category_id=c.id "\
            "WHERE c.name=? and p.name=?",
            [result['category'], result['package']]
        ).flatten()[0]

        if result['package_id'].nil?
            # means category/package that already does not exist in portage
            PLogger.warn(
                "File `package.keywords` contains package "\
                "(#{result['category']}/#{result['package']}) "\
                "that already is not present in portage"
            )

            return  
        end

        result_set = nil

        if result['version'] == '*'
            local_query = 'SELECT id FROM ebuilds WHERE package_id=?'
            result_set = Database.select(local_query, result['package_id']).flatten
        elsif result['version_restrictions'] == '=' && result['version'].end_with?('*')
            version_like = result['version'].sub('*', '')
            local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version like '#{version_like}%'"
            result_set = Database.select(local_query, result['package_id']).flatten
        else
            local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version#{result['version_restrictions']}?"
            result_set = Database.select(local_query, [result['package_id'], result['version']]).flatten
        end

        if result_set.size() > 0
            result_set.each { |version|
                result['arch'].each { |arch|
                    Database.add_data4insert([
                        version,
                        result['keyword'],
                        arch
                    ])
                }
            }
        else
            # means =category/atom-version that already does not exist in portage
            PLogger.warn(
                "File `package.keywords` contains atom "\
                "(#{result["version_restrictions"]}"\
                "#{result['category']}/#{result['package']}"\
                "-#{result["version"]}) "\
                "that already is not present in portage"
            )
        end
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO ebuild_keywords
        (ebuild_id, keyword_id, arch_id, source_id)
        VALUES (
            ?, ?, ?,
            (SELECT id FROM sources WHERE source='/etc/portage/')
        );
    SQL
})

