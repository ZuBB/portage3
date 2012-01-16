#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'optparse'
require 'rubygems'
require 'nokogiri'
require 'sqlite3'
require 'tools'

# hash with options
options = {
    :db_filename => nil,
    :storage => {},
    :quiet => true
}

# lets merge stuff from tools lib
options[:storage].merge!(STORAGE)
# get last created database
options[:db_filename] = get_last_created_database(
    options[:storage][:root],
    options[:storage][:home_folder]
)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: purge_s3_data [options]\n"
    opts.separator " A script that purges outdated data from s3 bucket\n"

    opts.on("-f", "--database-file STRING", "Path where new database file will be created") do |value|
        # TODO check if path id valid
        options[:db_filename] = value
    end

    # parsing 'quite' option if present
    opts.on("-q", "--quiet", "Quiet mode") do |value|
        options[:quiet] = true
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

portage_home = File.join(
    options[:storage][:root],
    options[:storage][:home_folder],
    options[:storage][:portage_home]
)

def get_package_maintainers(database, item_path)
    persons = []
    metadata_path = File.join(item_path, "metadata.xml")
    return persons unless (File.readable?(metadata_path) rescue false)

    Nokogiri::XML(IO.read(metadata_path)).xpath("//maintainer").each do |node|
        # lets get email and name
        email = node.xpath('email').inner_text rescue ''
        name = node.xpath('name').inner_text rescue ''
        # TODO also handle next tag and possible other tags/values
        # <description>Proxying maintainer.</description>

        # skip if email is empty or email is a stub
        next nil if email.empty? || 'maintainer-needed@gentoo.org' == email

        person = {}
        person["name"] = name
        person["email"] = email
        person["role"] = node.parent().name() == 'upstream' ?
            "upstream maintainer" : "gentoo maintainer"
        persons << person
    end

    return persons
end

def store_persons(database, persons)
    persons.each do |person|
        sql_query = "SELECT * FROM persons WHERE email=?;"
        result = database.execute(sql_query, person["email"])

        if (result.empty?)
            sql_query = "INSERT INTO persons (email, name) VALUES (?, ?);"
            database.execute(sql_query, person["email"], person["name"])
            person["person_id"] = get_last_inserted_id(database)
        else
            if !person["name"].empty? && result[0][1].empty?
                sql_query = "UPDATE persons SET name=? where id=?;"
                database.execute(sql_query, person["name"], result[0][0])
            end
            person["person_id"] = result[0][0]
        end
    end
end

def store_persons_responsibilities(database, persons)
    sql_query1 = <<SQL
SELECT id
FROM persons2roles
WHERE person_id=? and role_id = (
    SELECT id
    FROM roles
    WHERE role=?
);
SQL

    sql_query2 = <<SQL
INSERT INTO persons2roles
(person_id, role_id)
VALUES (?, (
    SELECT id
    FROM roles
    WHERE role=?
));
SQL

    persons.each do |person|
        result = database.execute(
            sql_query1,
            person["person_id"],
            person["role"]
        )

        if (result.empty?)
            database.execute(sql_query2, person["person_id"], person["role"])
            person["persons_role_id"] = get_last_inserted_id(database)
        else
            person["persons_role_id"] = result[0][0]
        end
    end
end

def store_package_maintainers(database, persons, package_id)
    sql_query = <<SQL
INSERT INTO person_roles2packages
(persons_role_id, package_id)
VALUES (?, ?);
SQL
    persons.each do |person|
        database.execute(sql_query, person["persons_role_id"], package_id)
    end
end

def fill_maintainers_table(database, portage_home)
    Dir.new(portage_home).sort.each do |category|
        # check if current item is valid for us
        next if is_category_invalid(portage_home, category)

        # lets walk through all items in category dir
        Dir.new(File.join(portage_home, category)).sort.each do |package|
            # lets get full path for this item
            item_path = File.join(portage_home, category, package)
            # skip if it is a ..
            next if is_package_invalid(item_path, package)

            persons = get_package_maintainers(database, item_path)
            persons = store_persons(database, persons)
            persons = store_persons_responsibilities(database, persons)
            package_id = get_package_id(database, category, package)
            store_package_maintainers(database, persons, package_id)
        end
    end
end

fill_maintainers_table(db, portage_home)
