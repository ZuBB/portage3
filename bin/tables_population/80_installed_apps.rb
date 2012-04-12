#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/22/12
# Latest Modification: Vasyl Zuzyak, ...
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'script'

script = Script.new({
    "script" => __FILE__,
    "sql_query" => <<SQL
INSERT INTO installed_apps
(package_id)
VALUES ((
    SELECT packages.id
    FROM packages, categories
    WHERE
        categories.category_name=? and
        categories.id=packages.category_id and
        packages.package_name=?
));
SQL
})

def fill_table(params)
    filename = "/var/lib/portage/world"
    file_content = IO.read(filename).to_a rescue []
    # walk through all use lines in that file
    file_content.each do |line|
        # lets trim newlines and insert
        line.chomp!()
        category_name = line.split('/')[0]
        package_name = line.split('/')[1]
        Database.insert({
            "sql_query" => params["sql_query"],
            "values" => [category_name, package_name]
        })
    end
end

script.fill_table_X(method(:fill_table))

