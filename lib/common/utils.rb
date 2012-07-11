#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'json'

module Utils
    OPTIONS = {
        "quiet" => true,
        "debug" => false,
        "db_filename" => nil
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

    def self.get_settings(settings_file = 'settings.json')
        config_path_parts = [File.dirname(__FILE__), '../..', 'config']
        settings_dir = File.expand_path(File.join(*config_path_parts))
        settings_file = File.join(settings_dir, settings_file)

        if  File.exist?(settings_file)
            begin
                data = JSON.parse(IO.read(settings_file))
            rescue
                msg = 'Can not parse settings file!'
            end
        else
            msg = 'Can not find settings file!'
        end

        if msg.nil?
            return data
        else
            throw msg
        end
    end

    def self.get_tree_home(settings = self.get_settings)
        # TODO fix this for case when deploy_type is not defined
        deploy_type = settings['deploy_type']
        settings['deployments'][deploy_type]['tree_home']
    end

    def self.get_profiles2_home(settings = self.get_settings)
        # TODO fix this for case when deploy_type is not defined
        deploy_type = settings['deploy_type']
        tree_home = settings['deployments'][deploy_type]['tree_home']
        File.join(tree_home, settings['new_profiles'])
    end

    def self.get_db_home(settings = self.get_settings)
        # TODO fix this for case when deploy_type is not defined
        deploy_type = settings['deploy_type']
        settings['deployments'][deploy_type]['db_home']
    end
end

