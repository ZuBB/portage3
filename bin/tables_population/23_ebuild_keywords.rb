#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/28/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'ebuild'

script = Script.new({
    "script" => __FILE__,
    "sql_query" => <<SQL
INSERT INTO package_keywords
(package_id, ebuild_id, keyword_id, arch_id, source_id)
VALUES (
    ?,
    ?,
    (SELECT id FROM keywords WHERE keyword=?),
    (SELECT id FROM arches WHERE arch_name=?),
    (SELECT id FROM sources WHERE source='ebuilds')
);
SQL
})

def store_ebuild_keywords(main_query, ebuild_obj)
    keywords, ebuild_obj["keywords"] = ebuild_obj["keywords"], []
    if keywords == '0_KEYWORDS_NF' || keywords.include?("*")
        sign = '-' if keywords.include?("-*")
        if keywords.include?("-*")
            ebuild_obj["keyword_minus_all"] = true
        end

        if keywords.include?("0_KEYWORDS_NF")
            sign = '?'
            ebuild_obj["keywords_real"] = '0_KEYWORDS_NF'
        end

        sql_query = "SELECT arch_name FROM arches;"
        arches = Database.db().execute(sql_query).flatten

        unless sign.nil?
            arches.map! { |arch| arch.insert(0, sign)}
        else
            # TODO handle this
        end

        if keywords.include?("0_KEYWORDS_NF")
            ebuild_obj["keywords"] = arches
            keywords.sub!("0_KEYWORDS_NF", '')
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
            ebuild_obj["keywords"] = arches
        end
    end

    keywords.split.each { |keyword| ebuild_obj["keywords"] << keyword }

    ebuild_obj["keywords"].each do |keyword|
        status, arch = 'stable', keyword
        status = 'unstable' if keyword.index('~') == 0
        status = 'not work' if keyword.index('-') == 0
        status = 'not known' if keyword.index('?') == 0
        arch = keyword.sub(/^./, '') if status != 'stable'

        Database.insert({
            "sql_query" => main_query,
            "values" => [
                ebuild_obj['package_id'],
                ebuild_obj['ebuild_id'],
                status,
                arch
            ]
        })
    end
end

def parse_ebuild(params)
    puts "Ebuild: #{params["filename"]}" if @debug
    ebuild = Ebuild.new(Utils.create_ebuild_params(params))

    return {
        'package_id' => ebuild.package_id(),
        'ebuild_id' => ebuild.ebuild_id(),
        'keywords' => ebuild.keywords()
    }
end

def category_block(params)
    Utils.walk_through_packages({"block2" => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    Dir.glob(File.join(params["item_path"], '*.ebuild')).each do |ebuild|
        store_ebuild_keywords(
            params["sql_query"],
            parse_ebuild({"filename" => ebuild}.merge!(params))
        )
    end
end

def fill_table(params)
    Utils.walk_through_categories(
        {"block1" => method(:category_block)}.merge!(params)
    )
end

script.fill_table_X(method(:fill_table))
