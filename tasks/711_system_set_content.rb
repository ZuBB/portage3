#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '041_packages;501_sets'
    self::TARGETS = ['packages']
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO set_content (set_id, package_id) VALUES (?, ?);
        SQL
    }

    def get_data(params)
        Portage3::Database.get_client
        .select(Portage3::Setting::SQL['@1'], 'profile')
        .flatten
    end

    def set_shared_data
        request_data('set@id', Portage3::Set::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(profile)
        Portage3::Profile.process_profile_dirs(profile, self.class::TARGETS)
        .each { |filename|
            IO.readlines(filename)
            .reject { |line| /^\s*#/ =~ line }
            .reject { |line| /^\s*$/ =~ line }
            .map    { |line| line.strip }
            .each   { |line|
                result = Atom.parse_atom_string(line)
                result['package_id'] = shared_data('CPN@id', result['atom'])

                if result['package_id'].nil?
                    @logger.warn("File `#{filename}` has dead package: #{line}")
                    next
                end

                send_data4insert({'data' => [
                    shared_data('set@id', 'system'),
                    result['package_id']
                ]})
            }
        }
    end
end

Tasks.create_task(__FILE__, klass)

