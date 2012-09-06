#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'

def get_data(params)
    results = []

    filename = '/var/lib/portage/world'
    return results unless File.exist?(filename)

    IO.read(filename)
    .lines
    .map { |line| line.strip }
    .reject { |line| line.empty? }
end

class Script
    DEFAULT_SET = 'installed'

    def pre_insert_task
        sql_query = 'select name, id from sets;'
        @shared_data['set@id'] = Hash[Database.select(sql_query)]

        @shared_data['atom@id'] = {}
        sql_query = <<-SQL
            select c.name, p.name, p.id
            from packages p
            join categories c on p.category_id=c.id;
        SQL
        Database.select(sql_query).each do |row|
            key = row[0] + '/' + row[1]
            @shared_data['atom@id'][key] = row[2]
        end
    end

    def process(params)
        Database.add_data4insert(
            @shared_data['set@id'][DEFAULT_SET],
            @shared_data['atom@id'][params]
        )
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO set_content
        (set_id, package_id)
        VALUES (?, ?);
    SQL
})

