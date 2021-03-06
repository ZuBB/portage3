#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '008_sources;059_use_flag_stuff'
    self::SOURCE = 'make.conf'
    self::TYPE = 'global'
    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO flags_states
            (flag_id, state_id, source_id)
            VALUES (?, ?, ?);
        SQL
    }

    def get_data(params)
        filepath = Portage3.settings_home
        return [] if filepath.nil?()

        # TODO get correct location for 'make.conf'
        file_content = IO.readlines(Portage3.settings_home)
        Parser.get_multi_line_ini_value(file_content, 'USE').split.uniq
    end

    def set_shared_data
        request_data('source@id', Source::SQL['@'])
        request_data('flag_state@id', UseFlag::SQL['@2'])
        request_data('global_flag@id', UseFlag::SQL['@3'])
    end

    def process_item(flag_spec)
        send_data4insert({
            'raw_data' => [
                 UseFlag.get_flag(flag_spec),
                 UseFlag.get_flag_state2(flag_spec),
                 self.class::SOURCE
            ],
            'data' => [
                 shared_data('global_flag@id', UseFlag.get_flag(flag_spec)),
                 # we have to use different method for getting state of flag
                 # because of https://github.com/zvasyl/portage3/wiki/Collisions-in-Gentoo
                 shared_data('flag_state@id', UseFlag.get_flag_state2(flag_spec)),
                 shared_data('source@id', self.class::SOURCE)
            ]
        })
    end
end

Tasks.create_task(__FILE__, klass)

