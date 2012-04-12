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

    def self.walk_through_categories(params)
        Dir.new(params["portage_home"]).sort.each do |category|
            # skip system dirs
            next if ['.', '..'].index(category) != nil
            # skip files
            next if File.file?(File.join(params["portage_home"], category))
            # skip any dirs tha does not have '-' in name or if its 'virtual'
            next if !category.include?('-') && category != 'virtual'

            params["block1"].call({"category" => category}.merge!(params))
        end
    end

    def self.walk_through_packages(params)
        dir = File.join(params["portage_home"], params["category"])
        Dir.new(dir).sort.each do |package|
            # lets get full path for this item
            item_path = File.join(dir, package)
            # skip system dirs
            next if ['.', '..'].index(package) != nil
            # skip files
            next if File.file?(item_path)

            params["block2"].call({
                "package" => package,
                "item_path" => item_path
            }.merge!(params))
        end
    end

    def self.create_ebuild_params(params)
        result = {
            "method" => params["method"],
            "portage_home" => params["portage_home"]
        }

        # category
        result["category"] = params["category"] if params["category"]

        # package
        result["package"] = params["package"] if params["package"]

        # filename
        result["filename"] = params["filename"] if params["filename"]

        return result
    end
end
