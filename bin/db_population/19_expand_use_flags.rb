#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/19/12
# Latest Modification: Vasyl Zuzyak, ...
#
require_relative 'envsetup'
require 'parser'
require 'useflag'

def get_data(params)
    results = []
    # pattern for flag, its description and package
    pattern = Regexp.new('([\\w\\+\\-]+)(?:\\s-\\s)(.*)')
    flag_type_id = Database.get_1value(UseFlag::SQL['type'], 'expand')
    # items to construct full path
    path_items = [params['profiles2_home'], 'desc', '*desc']
    # get exceptions
    file = File.join(params['profiles2_home'], 'base', 'make.defaults')
    exceptions = Parser.get_multi_line_ini_value(IO.read(file).split("\n"),
                                                 'USE_EXPAND_HIDDEN'
                                                ).split(' ')

    Dir.glob(File.join(*path_items)).each do |file|
        use_prefix = File.basename(file, '.desc')
        next if exceptions.include?(use_prefix.upcase())
        IO.foreach(file) do |line|
            line.chomp!()
            next if line.start_with?('#')
            next if line.empty?

            unless (match = pattern.match(line)).nil?
                results << [use_prefix, *match.to_a.drop(1), flag_type_id]
            end
        end
    end

    results.map { |row| row[0] += '_' + row.delete_at(1) ; row }
end

script = Script.new({
    'data_source' => method(:get_data),
    'sql_query' => <<-SQL
        INSERT INTO use_flags
        (flag_name, flag_description, flag_type_id)
        VALUES (?, ?, ?);
    SQL
})

