#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'source'
require 'profiles'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources;006_profiles'
    self::SOURCE = 'profiles'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_profile_categories
            (name, source_id)
            VALUES (?, ?);
        SQL
    }

    def get_data(params)
        PProfile.files_with_atoms(params)
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            atom = line.split[0]
            dirty_category = atom.split('/')[0]
            category = dirty_category.sub(/^[^\w]*/, '')
            source_id = shared_data('source@id', self.class::SOURCE)
            send_data4insert([category, source_id])
        end
    end
end

Tasks.create_task(__FILE__, klass)

