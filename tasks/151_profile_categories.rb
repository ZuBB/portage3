#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '006_profiles;031_categories'
    self::SOURCE = 'profiles'
    self::SQL = {
        'insert' => Category::SQL['insert'],
        'amount' => Category::SQL['amount']
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

            result = Atom.parse_atom_string(line.strip)
            source = shared_data('source@id', self.class::SOURCE)

            if result["category"].nil? || result["category"].empty?
                # TODO log
                next
            end

            send_data4insert([result["category"], source])
        end
    end
end

Tasks.create_task(__FILE__, klass)

