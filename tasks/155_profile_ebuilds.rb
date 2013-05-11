#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/26/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'repository'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '021_repositories;154_profile_packages'
    self::SOURCE = 'profiles'
    self::REPO = 'unknown'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO tmp_profile_ebuilds
            (package_id, version, repository_id, source_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        Portage3::Profile.files_with_atoms(params)
    end

    def set_shared_data
        request_data('repository@id', Repository::SQL['@'])
        request_data('source@id', Source::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(filename)
        IO.foreach(filename) do |line|
            next if /^\s*#/ =~ line
            next if /^\s*$/ =~ line

            result = Atom.parse_atom_string(line.strip)
            next if result['version'].nil?

            send_data4insert({
                'data' => [
                    shared_data('CPN@id', result['atom']),
                    result["version"],
                    shared_data('repository@id', self.class::REPO),
                    shared_data('source@id', self.class::SOURCE)
                ],
                'raw_data' => [
                    result['atom'],
                    result["version"],
                    self.class::REPO,
                    self.class::SOURCE
                ]
            })
        end
    end
end

Tasks.create_task(__FILE__, klass)

