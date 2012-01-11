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
    value = line.split('=')[1]
    value = value.gsub(/['"\\]*/, '')
    # TODO: escape chars in description
    # TODO: trim '\n' in ebuild lines
    #value = value.gsub(/^['"]/, '')
    #value = value.gsub(/['"]$/, '')
    #value = value.rchomp('"').chomp('"')
    #value = value.rchomp('\'').chomp('\'')
    return value
end

def get_last_created_database(root_path, home_folder)
    # get last test database
    return Dir.glob(File.join(root_path, home_folder) + '/*.sqlite').sort.last
end

