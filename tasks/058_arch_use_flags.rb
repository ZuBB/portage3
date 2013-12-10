#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#

klass = Class.new(Tasks::Runner) do
    self::DEPENDS = '053_use_flag_basic_stuff'
    self::SOURCE = 'profiles'
    self::REPO = 'gentoo'
    self::TYPE = 'arch'

    self::SQL = {
        'insert' => <<-SQL
            INSERT INTO flags
            (name, type_id, source_id, repository_id)
            VALUES (?, ?, ?, ?);
        SQL
    }

    def get_data(params)
        filename = File.join(params['profiles_home'], 'base', 'make.defaults')
        content = IO.read(filename).split("\n")
        Parser.get_multi_line_ini_value(content, 'USE_EXPAND_VALUES_ARCH').split
    end

    def set_shared_data
        request_data('flag_type@id', UseFlag::SQL['@1'])
        request_data('source@id', Source::SQL['@'])
        request_data('repo@id', Repository::SQL['@'])
    end

    def process_item(flag)
        params = [flag]
        params << shared_data('flag_type@id', self.class::TYPE)
        params << shared_data('source@id', self.class::SOURCE)
        params << shared_data('repo@id', self.class::REPO)

        send_data4insert({'data' => params})
    end
end

Tasks.create_task(__FILE__, klass)

