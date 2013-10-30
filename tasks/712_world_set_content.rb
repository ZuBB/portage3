#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '041_packages;701_sets'
    self::TARGETS = ['packages']
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO set_content (set_id, package_id) VALUES (?, ?);
        SQL
    }

    def get_data(params)
        filename = '/var/lib/portage/world'
        File.exist?(filename) ? IO.readlines(filename) : []
    end

    def set_shared_data
        request_data('set@id', Portage3::Set::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line
        line.strip!

        result = Atom.parse_atom_string(line)
        result['package_id'] = shared_data('CPN@id', result['atom'])

        if result['package_id'].nil?
            @logger.warn("File `#{filename}` has dead package: #{line}")
            return
        end

        send_data4insert({'data' => [
            shared_data('set@id', 'world'),
            result['package_id']
        ]})
    end
end

Tasks.create_task(__FILE__, klass)

