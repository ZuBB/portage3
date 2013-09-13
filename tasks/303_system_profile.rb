#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/07/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '006_profiles'
    self::SQL = {
        'insert' => 'INSERT INTO system_settings (param, value) VALUES (?, ?);'
    }

    def get_data(params)
        if Utils::SETTINGS['gentoo_os']
            config_path_parts = [File.dirname(__FILE__), '../', 'data']
            settings_dir = File.expand_path(File.join(*config_path_parts))
            settings_file = File.join(settings_dir, 'emerge_info')

			content = IO.readlines(settings_file)
            [['profile', Parser.get_multi_line_ini_value(content, 'PROFILE')]]
        else
            [['profile', 'default/linux/x86/13.0']]
        end
    end
end

Tasks.create_task(__FILE__, klass)

