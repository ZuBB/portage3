#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/28/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'ebuild'
require 'keyword'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '003_arches;004_keywords;008_sources;091_ebuilds'
    self::THREADS = 4
    self::SOURCE = 'ebuilds'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO ebuilds_keywords
            (ebuild_id, keyword_id, arch_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Ebuild.get_ebuilds(params)
    end

    def get_shared_data
        Tasks::Scheduler.set_shared_data('keyword@id', Keyword::SQL['@2'])
        Tasks::Scheduler.set_shared_data('source@id', Source::SQL['@'])
        Tasks::Scheduler.set_shared_data('arch@id', Keyword::SQL['@1'])
    end

    def process_item(params)
        PLogger.debug(@id, "Ebuild: #{params[3, 3].join('-')}")
        ebuild = Ebuild.new(Ebuild.generate_ebuild_params(params))
        Keyword.parse_ebuild_keywords(
            ebuild.ebuild_keywords,
            Tasks::Scheduler.class_variable_get(:@@shared_data)['arch@id'].keys
        ).each do |keyword_obj|
            send_data4insert({'data' => [
                ebuild.ebuild_id,
                shared_data('keyword@id', keyword_obj[1]),
                shared_data('arch@id', keyword_obj[0]),
                shared_data('source@id', self.class::SOURCE),
            ]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

