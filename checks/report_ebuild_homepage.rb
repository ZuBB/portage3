#!/usr/bin/env ruby

current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))

require 'portage3'

SQL_QUERY = <<-SQL
    select
        c.name || '/' || p.name || '-' || e.version as atom,
        eh.homepage,
        eh.notice,
        u.email,
        e.mauthor as last_committer,
        e.mtime as last_lodified
    from ebuild_homepages eh
    join ebuilds_homepages ehs on ehs.homepage_id = eh.id
    join ebuilds e on ehs.ebuild_id = e.id
    join packages p on e.package_id = p.id
    join categories c on p.category_id = c.id
    join packages2maintainers p2m on p2m.package_id = e.package_id
    join persons u on p2m.person_id = u.id
    where status = 'broken'
    order by u.email, homepage, e.version_order;
SQL

Portage3::Logger.start_server
Portage3::Database.init(Utils.get_database)
database = Portage3::Database.get_client

database.select(SQL_QUERY).each { |item|
    output = []
    output << "ebuild: #{item[0]}"
    output << "homepage: #{item[1]}"
    output << item[2]
    output << "maintainer email: #{item[3]}"
    output << "last committer: #{item[4]}"
    output << "last modified at: #{Time.at(item[5].to_i)}"
    output << "\n"
    puts output.join("\n")
}

database.shutdown_server

