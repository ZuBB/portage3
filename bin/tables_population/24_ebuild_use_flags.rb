#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 03/23/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'
require 'ebuild'

script = Script.new({
    "script" => __FILE__,
    "sql_query" => <<SQL
insert into use_flags2ebuilds
(package_id, ebuild_id, use_flag_id, flag_state, source_id)
VALUES (?, ?, (SELECT id FROM use_flags WHERE flag_name=?), ?, ?);
SQL
})

def parse_ebuild(params)
    PLogger.debug("Ebuild: #{params["filename"]}")
    ebuild = Ebuild.new(Utils.create_ebuild_params(params))

    return {
        'package_id' => ebuild.package_id(),
        'ebuild_id' => ebuild.ebuild_id(),
        'use_flags' => ebuild.use_flags()
    }
end

def store_ebuild_use_flags(main_query, ebuild_obj)
    use_flags = ebuild_obj['use_flags'].split(' ')
    puts 'USE duplication' if use_flags.size != use_flags.uniq.size
    use_flags.uniq!

    use_flags.each { |use_flag| 
        if use_flag[0] == 43 && use_flags.include?(use_flag.sub('+', ''))
            puts "USE duplication ('+' -> '')"
            use_flags.delete(use_flag.sub('+', ''))
        end
        if use_flag[0] == 45 && use_flags.include?(use_flag.sub('-', ''))
            puts "USE duplication ('-' -> '')"
            use_flags.delete(use_flag.sub('-', ''))
        end
    }

    use_flags = use_flags.join(' ')

    puts "Use flags: #{use_flags}" if @debug

    use_flags = use_flags.split(' ').map do |flag|
        flag_state = flag[0] == '+' ? 1 : 0
        flag_name = flag.sub(/^(-|\+)/, '')

        Database.insert({
            "sql_query" => main_query,
            "values" => [
                ebuild_obj['package_id'],
                ebuild_obj['ebuild_id'],
                flag_name,
                flag_state,
                1 # TODO source_id
            ]
        })
    end
end

def category_block(params)
    Utils.walk_through_packages({"block2" => method(:packages_block)}.merge!(params))
end

def packages_block(params)
    Dir.glob(File.join(params["item_path"], '*.ebuild')).each do |ebuild|
        store_ebuild_use_flags(
            params["sql_query"],
            parse_ebuild({"filename" => ebuild}.merge!(params))
        )
    end
end

def fill_table(params)
    Utils.walk_through_categories(
        {"block1" => method(:category_block)}.merge!(params)
    )
end

script.fill_table_X(method(:fill_table))

