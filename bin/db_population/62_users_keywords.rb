#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'keyword'
require 'ebuild'

def get_data(params)
    results = []

    filename = File.join(Utils.get_portage_settings_home, 'package.keywords')
    if File.exist?(filename) && !File.directory?(filename)
        results += IO.read(filename).split("\n")
    else
        Dir[File.join(filename, '**/*')].each { |file|
            results += IO.read(filename).split("\n") if File.size?
        }
    end

    results
end

class Script
    SOURCE = '/etc/portage/'

    def pre_insert_task
        @shared_data.merge!(Keyword.pre_insert_task(SOURCE))
        @shared_data['cur_arch'] = Database.get_1value(Keyword::SQL2)
        @shared_data['cur_keyword'] = Database.get_1value(Keyword::SQL2)
    end

    def process(line)
        return if line.start_with?('#')
        return if /^\s*$/ =~ line

        result = Keyword.parse_line(line.strip,
                                    @shared_data['cur_arch'],
                                    @shared_data['cur_keyword']
                                   )

        result['package_id'] = Keyword.get_package_id(result)
        return if result['package_id'].nil?

        result_set = Keyword.get_ebuild_ids(result)
        return if result_set.empty?

        result_set.each { |ebuild_id|
            params = [
                @shared_data['arches@id'][result['arch']],
                @shared_data['keywords@id'][result['keyword']],
                @shared_data['sources@id'][SOURCE],
            ]

            Database.add_data4insert(ebuild_id, *params)
        }
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO ebuild_keywords
        (ebuild_id, arch_id, keyword_id, source_id)
        VALUES (?, ?, ?, ?);
    SQL
})

