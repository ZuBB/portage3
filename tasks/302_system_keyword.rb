#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/07/12
# Latest Modification: Vasyl Zuzyak, ...
#

# TODO rewrite with data from data/emerge_infoo
klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '004_keywords'
    self::SQL = {
        'insert' => 'INSERT INTO system_settings (param, value) VALUES (?, ?);'
    }

    def get_data(params)
        if Utils::SETTINGS['gentoo_os']
			var = 'ACCEPT_KEYWORDS'
			content = IO.readlines('/etc/make.conf')
			value = Parser.get_multi_line_ini_value(content, var)
            [['keyword', value.start_with?('~') ? 'unstable' : 'stable']]
        else
            [['keyword', 'stable']]
        end
    end
end

Tasks.create_task(__FILE__, klass)

