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
require 'keyword'

class Script
    SOURCE = 'ebuilds'

    def pre_insert_task
        sql_query = 'SELECT name FROM arches'
        @shared_data['arches'] = Database.select(sql_query).flatten

        @shared_data.merge!(Keyword.pre_insert_task(SOURCE))
    end

    def process(params)
        PLogger.debug("Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        keywords = Keyword.parse_ebuild_keywords(ebuild.ebuild_keywords,
                                                 @shared_data['arches']
                                                )

        keywords.each do |keyword_ojb|
            params = [@shared_data['keywords@id'][keyword_ojb[1]]]
            params << @shared_data['arches@id'][keyword_ojb[0]]
            params << @shared_data['sources@id']['ebuilds']
            Database.add_data4insert(ebuild.ebuild_id, *params)
        end
    end
end

script = Script.new({
    'data_source' => Ebuild.method(:get_ebuilds),
    'sql_query' => <<-SQL
        INSERT INTO ebuilds_keywords
        (ebuild_id, keyword_id, arch_id, source_id)
        VALUES (?, ?, ?, ?);
    SQL
})

