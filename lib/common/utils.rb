#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

module Utils
    OPTIONS = {
        "quiet" => true,
        "debug" => false,
        "db_filename" => nil,
        "settings_folder" => '/etc/portage/',
        # It used to call this "root_path" or "root_folder"]
        # and seems its more correct
        "portage_home" => '/dev/shm/',
        "home_folder" => 'portage',
        "required_space" => 700
    }

    # pattern for db files
    TIMESTAMP = "%Y%m%d-%H%M%S"
    # atom prefix matcher
    RESTRICTION = Regexp.new("^[^\\w]+")
    # regexp to match version
    ATOM_VERSION = Regexp.new('((?:-)(\\d[^:]*))?(?:(?::)(\\d.*))?$')

    def self.get_timestamp()
        return Time.now.strftime(TIMESTAMP)
    end

    def self.get_full_tree_path(options)
        File.join(options["portage_home"], options["home_folder"])
    end

    def self.get_last_created_database(options)
        Dir.glob(File.join(options["portage_home"], '*.sqlite')).sort.last
    end

    def self.is_number?(string)
        true if Float(string) rescue false
    end
end
