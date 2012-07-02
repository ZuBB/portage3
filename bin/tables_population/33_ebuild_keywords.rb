#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/28/12
# Latest Modification: Vasyl Zuzyak, ...
#
lib_path_items = [File.dirname(__FILE__), '..', '..', 'lib']
$:.push File.expand_path(File.join(*(lib_path_items + ['common'])))
$:.push File.expand_path(File.join(*(lib_path_items + ['portage'])))
require 'script'
require 'ebuild'

def get_data(params)
    # results
    results = []
    # query
    sql_query = <<-SQL
        SELECT
            parent_folder,
            repository_folder,
            category_name,
            package_name,
            version
        FROM ebuilds e
        JOIN packages p on p.id=e.package_id
        JOIN categories c on p.category_id=c.id
        JOIN repositories r on r.id=e.repository_id
    SQL

    # lets walk through all packages
    Database.select(sql_query).each { |row|
        results << {
            'value' => row[3] + '-' + row[4] + '.ebuild',
            'parent_dir' => File.join(row[0], row[1], row[2], row[3])
        }
    }

    return results
end

def store_ebuild_keywords(ebuild)
    keywords = ebuild.ebuild_keywords

    if keywords == '0_KEYWORDS_NF' || keywords.include?("*")
        sign = '-' if keywords.include?("-*")
        sign = '?' if keywords.include?("0_KEYWORDS_NF")

        arches = Database.select('SELECT arch_name FROM arches').flatten

        unless sign.nil?
            arches.map! { |arch| arch.insert(0, sign)}
        else
            # TODO handle this
        end

        if keywords.include?("0_KEYWORDS_NF")
            keywords.sub!("0_KEYWORDS_NF", arches)
        else
            keywords.sub!('-*', '')
            old_arches = keywords.split()
            old_arches.each { |arch|
                arches.each { |archn|
                    if archn.sub(/^[~\-\?]/, '') == arch.sub(/^[~\-\?]/, '')
                        arches.delete_at(arches.index(archn))
                    end
                }
            }
            keywords = arches.join(' ')
        end
    end

    keywords.split.each do |keyword|
        status, arch = 'stable', keyword
        status = 'unstable' if keyword.index('~') == 0
        status = 'not work' if keyword.index('-') == 0
        status = 'not known' if keyword.index('?') == 0
        arch = keyword.sub(/^./, '') if status != 'stable'

        Database.insert({
            "values" => [
                ebuild.ebuild_id,
                status,
                arch
            ],
            "sql_query" => <<SQL
INSERT INTO ebuild_keywords
(ebuild_id, keyword_id, arch_id, source_id)
VALUES (
    ?,
    (SELECT id FROM keywords WHERE keyword=?),
    (SELECT id FROM arches WHERE arch_name=?),
    (SELECT id FROM sources WHERE source='ebuilds')
);
SQL
        })
    end
end

def process(params)
    PLogger.info("Ebuild: #{params["value"]}")
    store_ebuild_keywords(Ebuild.new(params))
end

script = Script.new({
    "script" => __FILE__,
    "thread_code" => method(:process),
    "data_source" => Ebuild.method(:get_data)
})

