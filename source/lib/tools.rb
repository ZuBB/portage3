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
    :system_home => '/etc/portage/',
    :storage => {
        :root => '/dev/shm',
        :home_folder => 'portage3_data',
        :portage_home => 'portage',
        :full_tree_path => nil,
        :required_space => 700
    },
}

def get_timestamp()
    return Time.now.strftime(TIMESTAMP)
end

def get_full_tree_path(options)
    File.join(
        options[:storage][:root],
        options[:storage][:home_folder],
        options[:storage][:portage_home]
    )
end

def get_last_created_database(options)
    return Dir.glob(File.join(
        options[:storage][:root],
        options[:storage][:home_folder],
        '/*.sqlite'
    )).sort.last
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
        if line.index(keyword) == 0
            value = line
            if !value.include?('=') && value.index('#') == 0
                # TODO what is correct value to set here
                value = '0_#'
            elsif ((value.include?('=') && !value.include?('#')) ||
                   (value.index('=') < Integer(value.index('#'))))
                # get rid of new line
                value = value.chomp() if !value.empty?
                # get rid of comments
                value = value.gsub(/#.+$/, '') if !value.empty?
                # get actually value only
                value = value.split('=')[1] if !value.empty?
                # strip \s at the end
                value = value.strip() if !value.empty?
                # strip quotes
                value = value.gsub(/['"]/, '') if !value.empty?
            else
                value = ''
            end

            values << value
        end
    }

    if (values.compact!.uniq! rescue []).size > 1
        # TODO replace false with some good condition
        print "found #{values.size} values of '#{keyword}'" if false
    end

    # TODO return values.join(',') rescue nil
    return values[0] rescue nil
end

def get_category_id(database, category)
    database.get_first_value(
        "SELECT id FROM categories WHERE category_name=?;",
        category
    )
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

    database.get_first_value(sql_query, category, package)
end

def get_last_inserted_id(database)
    return database.get_first_value("SELECT last_insert_rowid();")
end

def fill_table_X(db_filename, fill_table, params)
    start = Time.now

    database = SQLite3::Database.new(db_filename)
    # TODO do we need an try/catch here?
    fill_table.call({:database => database}.merge!(params))
    database.close() if database.closed? == false

    return start.to_i - Time.now.to_i
end

def walk_through_categories(params)
    Dir.new(params[:portage_home]).sort.each do |category|
        # skip system dirs
        next if ['.', '..'].index(category) != nil
        # skip files
        next if File.file?(File.join(params[:portage_home], category))
        #TODO what to do with this?
        next if !category.include?('-') && category != 'virtual'

        params[:block1].call({:category => category}.merge!(params))
    end
end

def walk_through_packages(params)
    dir = File.join(params[:portage_home], params[:category])
    Dir.new(dir).sort.each do |package|
        # lets get full path for this item
        item_path = File.join(dir, package)
        # skip system dirs
        next if ['.', '..'].index(package) != nil
        # skip files
        next if File.file?(item_path)

        params[:block2].call({
            :package => package,
            :item_path => item_path
        }.merge!(params))
    end
end
