#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'useflag'

def get_data(params)
    results = []
    # pattern for flag, its description and package
    pattern = Regexp.new("([\\w\\/\\-\\+]+:)?([\\w\\+\\-]+)(?: - )(.*)")
    flag_type_id = Database.get_1value(UseFlag::SQL['type'], 'local')

    IO.foreach(File.join(params['profiles2_home'], 'use.local.desc')) do |line|
        line.chomp!()
        next if line.start_with?('#')
        next if line.empty?
        results << [*pattern.match(line).to_a.drop(1), flag_type_id]
    end

    results
end

class Script
    def pre_insert_task()
        @shared_data['atom@id'] = {}
        sql_query = <<-SQL
            SELECT p.id, c.category_name, p.package_name
            FROM packages p
            JOIN categories c ON p.category_id = c.id;
        SQL
        Database.select(sql_query).each do |row|
            @shared_data['atom@id'][row[1] + '/' + row[2]] = row[0]
        end
    end

    def process(params)
        Database.add_data4insert(params[1], params[2], params[3],
                                 @shared_data['atom@id'][params[0][0..-2]]
                                )
    end
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO use_flags
        (flag_name, flag_description, flag_type_id, package_id)
        VALUES (?, ?, ?, ?);
    SQL
})

