#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#

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
        Portage3::Profile.files_with_atoms(params)
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            send_data4insert([
                 Atom.parse_atom_string(line.strip)["category"],
                shared_data('source@id', self.class::SOURCE)
            ])
        end
    end
end

Tasks.create_task(__FILE__, klass)

