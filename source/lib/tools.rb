#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/07/12
#
require 'time' unless Object.const_defined?(:Time)

TIMESTAMP = "%Y%m%d-%H%M%S"
OPTIONS = {
    :quiet => true,
    :db_filename => nil,
    :storage => {
        :root => '/dev/shm',
        :home_folder => 'portage3_data',
        :portage_home => 'portage',
        :full_tree_path => nil,
        :required_space => 700
    },
}

def get_full_tree_path(options)
    File.join(
        options[:storage][:root],
        options[:storage][:home_folder],
        options[:storage][:portage_home]
    )
end

def get_timestamp()
    return Time.now.strftime(TIMESTAMP)
end

def get_last_inserted_id(database)
    return database.execute("SELECT last_insert_rowid();").flatten[0]
end

def clean_ini_value(line)
    # TODO: move it inside parent function
    value = line
    if !value.include?('=') && value.index('#') == 0
        # TODO what is correct value to set here
        value = '0_#'
    elsif ((value.include?('=') && !value.include?('#')) ||
           (value.index('=') < Integer(value.index('#'))))
        # get rid of new line
        value = value.chomp() if !value.empty?
        # get rid of comments
        value = value.gsub(/#.+$/, '')
        # get actually value only
        value = value.split('=')[1] if !value.empty?
        # strip \s at the end
        value = value.strip() if !value.empty?
        # strip quotes at the begining
        value = value.gsub(/^['"]/, '') if !value.empty?
        # strip quotes at the end
        value = value.gsub(/['"]$/, '') if !value.empty?
    else
        value = ''
    end

    return value
end

def get_value_from_cvs_header(ebuild_text, regexp)
    ebuild_text.each { |line|
        if line.include?('# $Header:') # TODO: or index == 0 ?
            # https://bugs.gentoo.org/show_bug.cgi?id=398567
            match = line.match(regexp)
            match = match[1] if !match.nil? && !match[1].nil?
            return (match.to_s rescue nil)
        end
    }

    return nil
end

def get_single_line_ini_value(ebuild_text, keyword)
    values = []
    ebuild_text.each { |line|
        # '==' because of app-editors/nvi/nvi-1.81.6-r3.ebuild
        values << clean_ini_value(line) if line.index(keyword) == 0
    }

    if (values.compact!.uniq! rescue []).size > 1
        # TODO replace false with some good condition
        print "found #{values.size} values of '#{keyword}'" if false
    end

    # TODO return values.join(',') rescue nil
    return values[0] rescue nil
end

def get_last_created_database(options)
    return Dir.glob(File.join(
        options[:storage][:root],
        options[:storage][:home_folder],
        '/*.sqlite'
    )).sort.last
end

def get_package_id(database, category, package)
    sql_query = <<SQL
SELECT packages.id
FROM packages, categories
WHERE
    categories.category_name=? and
    packages.package_name=? and
    packages.category_id = categories.id
SQL

    # get category_id
    database.execute(sql_query, category, package)[0][0]
end

def fill_table_X(db_filename, table_name, fill_table, params)
    # TODO: check if all dependant tables are filled
    start = Time.now

    database = SQLite3::Database.new(db_filename)
    # TODO params
    # TODO do we need an try/catch here?
    fill_table.call(database, params)
    database.close() if database.closed? == false

    return start.to_i - Time.now.to_i
end
