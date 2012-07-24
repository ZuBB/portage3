#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/28/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'ebuild'

class Script
    def get_shared_data()
        sql_query = 'SELECT arch_name FROM arches'
        @shared_data['arche'] = Database.select(sql_query).flatten
    end

    def process(params)
        PLogger.info("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        keywords = ebuild.ebuild_keywords

        if keywords == '0_KEYWORDS_NF' || keywords.include?("*")
            # TODO '-' is not the only one possible sign for 'x*' case
            sign = '-' if keywords.include?("-*")
            sign = '?' if keywords.include?("0_KEYWORDS_NF")

            arches = @shared_data['arche'].clone

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
                # TODO replace '=' with '+='?
                keywords = arches.join(' ')
            end
        end

        keywords.split.each do |keyword|
            status, arch = 'stable', keyword
            status = 'unstable' if keyword.index('~') == 0
            status = 'not work' if keyword.index('-') == 0
            status = 'not known' if keyword.index('?') == 0
            arch = keyword.sub(/^./, '') if status != 'stable'

            # TODO 'source_id' is hardcoded
            Database.add_data4insert(ebuild.ebuild_id, status, arch, 1)
        end
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO ebuild_keywords
        (ebuild_id, keyword_id, arch_id, source_id)
        VALUES (
            ?,
            (SELECT id FROM keywords WHERE keyword=?),
            (SELECT id FROM arches WHERE arch_name=?),
            ?
        );
    SQL
})

