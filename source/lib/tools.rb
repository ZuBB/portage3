#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/07/12
#
require 'time' unless Object.const_defined?(:Time)

TIMESTAMP = "%Y%m%d-%H%M%S"
STORAGE = {
    :home_folder => 'portage3_data',
    :portage_home => 'portage',
    :required_space => 700,
    :root => '/dev/shm'
}

def get_timestamp()
    return Time.now.strftime(TIMESTAMP)
end

def get_last_inserted_id(database)
    return database.execute("SELECT last_insert_rowid();").flatten[0]
end

def get_clean_value(line)
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

def get_last_created_database(root_path, home_folder)
    # get last test database
    return Dir.glob(File.join(root_path, home_folder) + '/*.sqlite').sort.last
end

