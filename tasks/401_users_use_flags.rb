#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'atom'
require 'source'
require 'useflag'

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '059_use_flag_stuff'
    self::SOURCE = '/etc/portage'
    self::TYPE = 'unknown'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO flags_states
            (state_id, package_id, source_id, flag_id)
            VALUES (?, ?, ?, (
                SELECT id FROM flags f
                /* NOTE hardcoded constants */
                WHERE name=? AND (f.type_id BETWEEN 4 and 6)
                ORDER BY f.type_id ASC
                LIMIT 1
            ));
        SQL
    }

    def get_data(params)
        Portage3.package_asterisk_content('package.use')
    end

    def set_shared_data
        request_data('flag_state@id', UseFlag::SQL['@2'])
        request_data('source@id', Source::SQL['@'])
        request_data('CPN@id', Atom::SQL['@1'])
    end

    def process_item(line)
        return if /^\s*#/ =~ line
        return if /^\s*$/ =~ line

        line       = line.sub(/#.*$/, '')
        flags      = line.split
        atom       = flags.delete_at(0)
        package_id = shared_data('CPN@id', atom)

        if line.include?('*')
            flags = UseFlag.expand_asterix_flag(flags, package_id)
        end

        flags.each { |flag|
            send_data4insert({'data' => [
                shared_data('flag_state@id', UseFlag.get_flag_state(flag)),
                package_id,
                shared_data('source@id', self.class::SOURCE),
                UseFlag.get_flag(flag)
            ]})
        }
    end
end

Tasks.create_task(__FILE__, klass)

