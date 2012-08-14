#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/01/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []
    sql_query = 'SELECT id FROM mask_states WHERE state=?'
    ['package.mask', 'package.unmask'].each do |file|
        filename = File.join(Utils.get_portage_settings_home, file)
        if File.exist?(filename) && File.file?(filename)
            mask_state = File.extname(filename) == '.unmask' ? 'unmasked' : 'masked'
            mask_state_id = Database.get_1value(sql_query, mask_state)

            IO.foreach(filename) do |line|
                next if line.index('#') == 0
                next if line.chomp!().empty?()

                results << [line, mask_state_id]
            end
        end
    end

    return results
end

def parse_line(line)
    result = {}

    # take care about leading ~
    # it means match any subrevision of the specified base version.
    if line.index('~') == 0
        line.sub!(/^~/, '')

        if line.include?(':')
            line.sub!(':', '*:') unless line.include?('*:')
        else
            line << '*' unless line.end_with?('*')
        end
    end

    # version restrictions
    unless line.match(Utils::RESTRICTION).nil?
        result['version_restrictions'] = line.match(Utils::RESTRICTION).to_s
        line.sub!(Utils::RESTRICTION, '')
    end

    # deal with versions
    version_match = line.match(Utils::ATOM_VERSION)
    version_match = version_match.to_a.compact unless version_match.nil?
    version_match = nil if version_match.size == 1 && version_match.to_s.empty?

    unless version_match.nil?
        result['version'] = version_match.last
        result['version'] << '*' if version_match.size == 2

        if result['version_restrictions'].nil?
            result['version_restrictions'] = '='
        end

        line.sub!(Utils::ATOM_VERSION, '')
    else
        result['version'] = '*'
        result['version_restrictions'] = '='
    end

    match = line.split('/')
    result['category'] = match[0]
    result['package'] = match[1]

    return result
end

def get_arch_id()
    return Database.get_1value(
        'SELECT value FROM system_settings WHERE param=?;', ['arch']
    )
end

class Script
    def process(params)
        line = params[0]

        result = parse_line(line)

        result['package_id'] = Database.get_1value(
            "\
            SELECT packages.id \
            FROM packages, categories \
            WHERE \
            categories.name=? and \
            packages.name=? and \
            packages.category_id = categories.id",
            [result['category'], result['package']]
        )

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

        result['arch'] = get_arch_id()

        if result_set.size() > 0
            result_set.each { |version|
                Database.add_data4insert([
                    version,
                    result['arch'],
                    params[1]
                ])
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
        INSERT INTO ebuilds_masks
        (ebuild_id, arch_id, state_id, source_id)
        VALUES (
            ?, ?, ?, (SELECT id FROM sources WHERE source='/etc/portage/')
        );
    SQL
})

