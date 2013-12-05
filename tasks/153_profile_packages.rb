#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'category'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '151_profile_categories'
    self::SOURCE = 'profiles'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_profile_packages
            (name, category_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        Portage3::Profile.files_with_atoms(params)
    end

    def set_shared_data
        request_data('category@id', Category::SQL['@'])
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            result = Atom.parse_atom_string(line.strip)
            send_data4insert({'data' => [
                result['package'],
                shared_data('category@id', result["category"]),
                shared_data('source@id', self.class::SOURCE)
            ]})
        end
    end
end

Tasks.create_task(__FILE__, klass)

