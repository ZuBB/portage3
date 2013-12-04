#!/usr/bin/env ruby

current_dir = File.dirname(__FILE__)
$:.push File.expand_path(File.join(current_dir, '..', 'lib'))

require 'optparse'
require 'portage3'

SQL_QUERY_P1 = "c.name || '/' || p.name || '-' || e.version as atom"
SQL_QUERY_P2 = <<-SQL
    from ebuild_homepages eh
    join ebuilds_homepages ehs on ehs.homepage_id = eh.id
    join ebuilds e on ehs.ebuild_id = e.id
    join packages p on e.package_id = p.id
    join categories c on p.category_id = c.id
    join packages2maintainers p2m on p2m.package_id = e.package_id
    join persons u on p2m.person_id = u.id
SQL
SQL_QUERY_P3 = 'order by u.email, homepage, e.version_order;'

options = {
    "status"   => 'broken',
    "homepage" => true,
    "email"    => true,
    "info"     => true
}

OptionParser.new do |opts|
    opts.banner = " Usage: report_ebuild_homepage2 [options]"
    opts.separator "\n A script that generates health report for homepage URLs"

    opts.on("-c", "--[no-]commiter", "Include last commiter (off by default)") do |value|
        options["commiter"] = value
    end

    opts.on("-d", "--[no-]date", "Include last modified date (off by default)") do |value|
        options["date"] = value
    end

    opts.on("-E", "--[no-]email", "Include email (on by default)") do |value|
        options["email"] = value
    end

    if false # TODO
    opts.on("-e", "--maintainers-email STRING", "Filter packages by maintainer's email") do |value|
        options["m_email"] = value
    end
    end

    opts.on("-H", "--[no-]homepage", "Include homepage (on by default)") do |value|
        options["homepage"] = value
    end

    opts.on("-i", "--[no-]info", "Include additional info of page check (on by default)") do |value|
        options["info"] = value
    end

    if false # TODO
    opts.on("-m", "--maintainers-name STRING", "Filter packages by maintainer's name") do |value|
        options["m_name"] = value
    end
    end

    opts.on("-M", "--[no-]name STRING", "Include name") do |value|
        options["name"] = value
    end

    if false # TODO
    opts.on("-n", "--maintainers-nick STRING", "Filter packages by maintainer's nickname") do |value|
        options["m_nick"] = value
    end
    end

    opts.on("-N", "--[no-]nick STRING", "Include nick") do |value|
        options["nick"] = value
    end

    opts.on("-s", "--status STRING", "Filter packages by homepage status") do |value|
        options["status"] = value
    end

    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

sql_query = []
selected_fields = [SQL_QUERY_P1]

selected_fields << 'eh.homepage' if options["homepage"]
selected_fields << 'eh.notice'   if options["info"]
selected_fields << 'u.email'     if options["email"]
selected_fields << 'e.mauthor'   if options["commiter"]
selected_fields << 'e.mtime'     if options["date"]
selected_fields << 'u.nickname'  if options["nickname"]
selected_fields << 'u.name'      if options["maintainer"]

sql_query << 'select ' + selected_fields.join(', ')
sql_query << SQL_QUERY_P2
sql_query << 'where status = ?'
sql_query << SQL_QUERY_P3

sql_query = sql_query.join(' ')

Portage3::Logger.start_server
Portage3::Database.init(Utils.get_database)
database = Portage3::Database.get_client
database.class::SERVER.class_variable_get(:@@database).results_as_hash = true

database.select(sql_query, options["status"]).each { |item|
    output = []
    output << "ebuild: #{item['atom']}"
    output << "homepage: #{item['homepage']}" if options["homepage"]
    output << item['notice'] if options["info"]
    output << "maintainer name: #{item['name']}" if options["maintainer"]
    output << "maintainer email: #{item['email']}" if options["email"]
    output << "maintainer nickname: #{item['nickname']}" if options["nickname"]
    output << "last committer: #{item['mauthor']}" if options["commiter"]
    output << "last modified at: #{Time.at(item['mtime'].to_i)}" if options["date"]
    puts (output.join("\n") + "\n\n")
}

database.shutdown_server

