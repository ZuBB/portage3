#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/07/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '003_arches'
    self::SQL = {
        'insert' => 'INSERT INTO system_settings (param, value) VALUES (?, ?);'
    }

    def get_data(params)
        if Utils::SETTINGS['gentoo_os']
            var = 'ACCEPT_KEYWORDS'
            content = IO.readlines(Portage3.settings_home())
            value = Parser.get_multi_line_ini_value(content, var)
            [['arch', value.sub(/^~/, '')]]
        else
            [['arch', 'x86']]
        end
    end
end

Tasks.create_task(__FILE__, klass)

