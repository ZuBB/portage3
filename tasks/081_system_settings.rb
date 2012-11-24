#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 02/07/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'parser'

# TODO rewrite with data from data/emerge_infoo
klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '003_arches;004_keywords'
    self::SQL = {
        'insert' => 'INSERT INTO system_settings (param, value) VALUES (?, ?);'
    }

    def get_data(params)
        accept_keywords = Parser.get_multi_line_ini_value(
            IO.read('/etc/make.conf').split("\n"),
            'ACCEPT_KEYWORDS'
        )

        if accept_keywords.include?('0_ACCEPT_KEYWORDS')
            puts 'Error Can not find `ACCEPT_KEYWORDS` variable in make.conf'
            exit(1)
        end

        keyword_name = accept_keywords.index('~') == 0 ? 'unstable' : 'stable'
        arch_name = accept_keywords.sub(/^~/, '')

        [
            ['arch', arch_name],
            ['keyword', keyword_name]
        ]
    end
end

Tasks.create_task(__FILE__, klass)

