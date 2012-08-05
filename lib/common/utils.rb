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

    def self.get_timestamp
        Time.now.strftime(TIMESTAMP)
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

        throw msg unless msg.nil?
        data
    end

    def self.get_pathes()
        deploy_type = SETTINGS['deploy_type']
        portage_home = SETTINGS['deployments'][deploy_type]['tree_home']
        profiles_home = File.join(portage_home, "profiles")
        new_profiles_home = File.join(portage_home, SETTINGS['new_profiles'])

        {
            'tree_home' => portage_home,
            'profiles2_home' => new_profiles_home,
            # TODO check if it can be removed
            'profiles_home' => profiles_home
        }
    end

    def self.get_tree_home()
        # TODO fix this for case when deploy_type is not defined
        deploy_type = SETTINGS['deploy_type']
        SETTINGS['deployments'][deploy_type]['tree_home']
    end

    def self.get_profiles2_home()
        # TODO fix this for case when deploy_type is not defined
        deploy_type = SETTINGS['deploy_type']
        tree_home = SETTINGS['deployments'][deploy_type]['tree_home']
        File.join(tree_home, SETTINGS['new_profiles'])
    end

    def self.get_db_home()
        # TODO fix this for case when deploy_type is not defined
        deploy_type = SETTINGS['deploy_type']
        SETTINGS['deployments'][deploy_type]['db_home']
    end

    def self.get_log_home()
        # TODO fix this for case when deploy_type is not defined
        deploy_type = SETTINGS['deploy_type']
        SETTINGS['deployments'][deploy_type]['log_home']
    end

    def self.get_portage_settings_home()
        SETTINGS['settings_home']
    end

    def self.get_database()
        Dir.glob(File.join(self.get_db_home(), '*.sqlite')).sort.last
    end

    SETTINGS = Utils.get_settings() unless $0.end_with?('01_generate_config.rb')
end

