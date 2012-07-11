#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'envsetup'
require 'script'

def get_data2(params)
    # query
    results = []
    FileUtils.cd(params['profiles2_home'])

    # walk through all use flags in that file
    Dir['**/package.mask'].each do |filename|
        # skip dirs that has 'deprecated' file in it
        next if File.exist?(File.join(
            params['profiles2_home'], filename.sub('package.mask', 'deprecated')
        ))

        results << filename
    end

    return results
end

def get_data(params)
    # walk through all use flags in that file
    Dir[File.join(params['profiles2_home'], '**/package.mask')].delete_if { |i|
        # skip dirs that has 'deprecated' file in it
        File.exist?(i.sub('package.mask', 'deprecated'))
    }
end

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
        Database.select("SELECT id FROM arches").flatten
    elsif dir.count('/') == 2
        sql_query = <<-SQL
            SELECT id
            FROM arches
            WHERE architecture_id=
                (SELECT id from architectures where architecture=?)
        SQL
        Database.select(sql_query, dir.split('/')[1]).flatten
    else
        sql_query = <<-SQL
            SELECT id
            FROM arches
            WHERE
                architecture_id=(
                    SELECT id FROM architectures WHERe architecture=?
                ) AND
                platform_id=(SELECT id FROM platforms WHERe platform_name=?)
        SQL
        Database.select(sql_query, [dir.split('/')[1], dir.split('/')[2]]).flatten
    end
end

def process(params)
    PLogger.debug("File: #{params["value"]}")
    filename = params["value"]

    IO.foreach(filename) do |line|
        # skip comments
        next if line.index('#') == 0
        # skip empty lines
        next if line.chomp!().empty?

        result = parse_line(line)

        result['package_id'] = Database.select(
            "SELECT p.id "\
            "FROM packages p "\
            "JOIN categories c on p.category_id=c.id "\
            "WHERE c.category_name=? and p.package_name=?",
             [result['category'], result['package']]
        ).flatten()[0]

        if result['package_id'].nil?
            # means category/package that already does not exist in portage
            PLogger.warn(
                "File `#{filename}` contains package "\
                "(#{result['category']}/#{result['package']}) "\
                "that already is not present in portage"
            )
            next 
        end

        result_set = nil

        if result["version"] == '*'
            local_query = "SELECT id FROM ebuilds WHERE package_id=?"
            result_set = Database.select(local_query, result["package_id"]).flatten
        elsif result["version_restrictions"] == '=' && result["version"].end_with?('*')
            version_like = result["version"].sub('*', '')
            local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version like '#{version_like}%'"
            result_set = Database.select(local_query, result["package_id"]).flatten
        else
            local_query = "SELECT id FROM ebuilds WHERE package_id=? AND version#{result["version_restrictions"]}?"
            result_set = Database.select(local_query, [result["package_id"], result["version"]]).flatten
        end

        result["arch"] = get_arch_id(filename)

        if result_set.size() > 0
            result_set.each { |version|
                result['arch'].each { |arch|
                    Database.add_data4insert([
                        version,
                        arch,
                        get_source_id(filename),
                        result["mask_state"]
                    ])
                }
            }
        else
            # means =category/package-version that already does not exist in portage
            PLogger.warn(
                "File `#{filename}` contains atom "\
                "(#{result["version_restrictions"]}"\
                "#{result['category']}/#{result['package']}"\
                "-#{result["version"]}) "\
                "that already is not present in portage"
            )
        end
    end
end

script = Script.new({
    'script' => __FILE__,
    'thread_code' => method(:process),
    'data_source' => method(:get_data),
    "sql_query" => <<-SQL
        INSERT INTO ebuild_masks
        (ebuild_id, arch_id, source_id, mask_state_id)
        VALUES (
            ?, ?, ?,
            (SELECT id FROM mask_states WHERE mask_state=?)
        );
    SQL
})

