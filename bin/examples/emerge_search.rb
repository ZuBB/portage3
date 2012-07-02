#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/11/12
# Latest Modification: Vasyl Zuzyak, 01/11/12
#
$:.push File.expand_path(File.join(File.dirname(__FILE__), '../../lib/common'))
require 'optparse'
require 'rubygems'
require 'sqlite3'
require 'utils'

def print_ebuild_specs(local_data)
    template = TEMPLATE.clone()
    versions = []

    local_data['VERSIONS'].each_index do |index|
        keyword_id = local_data['keywords'][index]
        keyword_index = KEYWORDS.index { |i| i[0] == keyword_id}
        keyword_name = KEYWORDS[keyword_index][1]
        keyword = KEYWORD_SIGNS[keyword_name]
        keyword = '(' + keyword + ')' if keyword.size > 0

        mask_state = local_data['mask_states'][index].nil?() ? '' : '[M]'

        versions << keyword + local_data['VERSIONS'][index] + mask_state
    end

    local_data.keys.each do |key|
        next if key.match(/[[:lower:]]/)
        template.sub!(key, local_data[key].join(' '))
    end

    puts template
end

def prepare_sql_pattern(pattern, regexp_pattern)
    return nil if pattern.nil?()

    if regexp_pattern
        pattern.sub!(/^\^?\*/, '%')
        pattern.sub!(/\*\$?$/, '%')
        pattern.gsub!(/\*/, '%')
        pattern.sub!(/^\^/, '')
        pattern.sub!(/\$$/, '')
    else
        pattern.gsub!(/[*^$]/, '')
        pattern = '%' + pattern + '%'
    end

    return pattern
end

def prepare_params(raw_pattern, also_desc)
    # drop quotes if present
    package_pattern = raw_pattern.match(/^['"]?([^'"]+)['"]?$/)[1].to_s
    regexp_pattern = false
    category_pattern = nil
    result = []
    names = []

    # check if we have regexps
    if package_pattern.start_with?('%')
        regexp_pattern = true
        package_pattern.slice!(0)
    end

    # check if we have category[ pattern]
    if package_pattern.start_with?('@')
        package_pattern.slice!(0)
        category_pattern = package_pattern.slice(0, pattern.index('/') - 1)
    end

    category_pattern = prepare_sql_pattern(category_pattern, regexp_pattern)
    package_pattern = prepare_sql_pattern(package_pattern, regexp_pattern)

    unless category_pattern.nil?()
        names << 'c.category_name'
        names << (category_pattern.include?('%') ? 'like' : '=') + ' ? AND '
        result << category_pattern
    end

    names << "(p.package_name"
    names << (package_pattern.include?('%') ? 'like' : '=') + ' ?'
    result << package_pattern

    if also_desc
        names << 'OR ed.description '
        names << (package_pattern.include?('%') ? 'like' : '=') + ' ?'
        result << package_pattern
    end

    names << ')'
    result << SQL_QUERY.clone().sub('MAIN_PATTERN', names.join(' '))
    result.reverse()
end

def search(raw_pattern, flag = false)
    package_id = nil
    local_data = nil

    @database.execute(*prepare_params(raw_pattern, flag)) do |row|
        if package_id != row[0]
            print_ebuild_specs(local_data) if !local_data.nil?
            local_data = Hash.new().merge!(PackageData)
            local_data['CATEGORY'] = [row[1]]
            local_data['PACKAGE'] = [row[2]]
            package_id = row[0]
        end

        local_data['VERSIONS'] << row[3]
        local_data['keywords'] << row[4]
        local_data['DESCRIPTION'] = [row[6]]
        local_data['mask_states'] << row[5]
        (local_data['HOMEPAGE'] << row[7]).uniq!()
    end
    print_ebuild_specs(local_data) if !local_data.nil?
end

# hash with options
options = {
    :search => nil,
    :searchdesc => nil
}

options.merge!(Utils::OPTIONS)

OptionParser.new do |opts|
    # help header
    opts.banner = " Usage: emerge_search [options]\n"
    opts.separator " A script does same search as emerge application\n"

    opts.on("-f", "--database-file STRING",
            "Path where new database file will be created") do |value|
        # TODO check if path id valid
        options[:db_filename] = value
    end

    opts.on("-s", "--search STRING",
        "Does same kind of search as 'emerge -s PATTERN' (see 'man port"\
        "age' for details). Note: if category (or its pattern) has been"\
        " specified it should be separated with package (or its pattern"\
        ") by '\'. This means that usage of '@' sign is optional"
    ) do |value|
            options[:search] = value
    end

    opts.on("-S", "--searchdesc STRING",
        "Does same kind of search as 'emerge -S PATTERN'. "\
        "See 'man portage' for details."
    ) do |value|
        options[:searchdesc] = value
    end

    # parsing 'help' option if present
    opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
    end
end.parse!

# get true portage home
if options[:db_filename].nil?
    # get last created database
    options[:db_filename] = Utils.get_last_created_database(options)
end

@database = SQLite3::Database.new(options[:db_filename])
MASK_STATES = @database.execute('select * from mask_states')
KEYWORDS = @database.execute('select * from keywords')
TEMPLATE = <<TEMPLATE
*  CATEGORY/PACKAGE
      Version available: VERSIONS
      Latest version available: [ Not implemented yet ]
      Latest version installed: [ Not implemented yet ]
      Size of files: [ Not implemented yet ]
      Homepage:      HOMEPAGE
      Description:   DESCRIPTION
      License:       [ Not implemented yet ]\n
TEMPLATE
KEYWORD_SIGNS = {
    'stable' => '',
    'unstable' => '~',
    'not work' => '-',
    'not known' => '?'
}
PackageData = {
    "CATEGORY" => [],
    "PACKAGE" => [],
    "VERSIONS" => [],
    "HOMEPAGE" => [],
    "DESCRIPTION" => [],
    "keywords" => [],
    "mask_states" => []
}
SQL_QUERY = <<-SQL
    SELECT
        e.package_id,
        c.category_name,
        p.package_name,
        e.version,
        ek.keyword_id,
        em.mask_state_id,
        ed.description,
        eh.homepage
    FROM ebuilds e
    JOIN packages p ON p.id=e.package_id
    JOIN categories c ON c.id=p.category_id
    JOIN ebuild_descriptions ed ON ed.id=e.description_id
    JOIN ebuild_homepages eh ON eh.id=e.homepage_id
    JOIN ebuild_keywords ek ON ek.ebuild_id=e.id
    LEFT JOIN ebuild_masks em
        ON em.ebuild_id=e.id AND em.arch_id = ek.arch_id
    WHERE
        MAIN_PATTERN AND
        ek.arch_id = (
            SELECT value FROM system_settings WHERE param='arch'
        )
    GROUP BY e.id
    ORDER BY c.category_name, p.package_name, e.version_order ASC
SQL

if !options[:search].nil?
    search(options[:search])
elsif !options[:searchdesc].nil?
    search(options[:searchdesc], false)
else
    puts 'No search pattern was specified'
end

@database.close

