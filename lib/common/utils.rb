#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'json'

module Utils
    # pattern for db files
    TIMESTAMP = "%Y%m%d-%H%M%S-UTC"

    def self.get_timestamp
        Time.now.gmtime.strftime(TIMESTAMP)
    end

    def self.is_number?(string)
        true if Float(string) rescue false
    end

    def self.get_settings(settings_file = 'settings.json')
        config_path_parts = [File.dirname(__FILE__), '../..', 'data']
        settings_dir = File.expand_path(File.join(*config_path_parts))
        settings_file = File.join(settings_dir, settings_file)

        if  File.exist?(settings_file)
            begin
                data = JSON.parse(IO.read(settings_file))
            rescue
                msg = 'Can not parse settings file!'
            end
        else
            puts 'Error: can not find settings file!'
            exit(false)
        end

        data
    end

    def self.get_pathes
        portage_home = SETTINGS['tree_home']
        profiles_home = File.join(portage_home, 'profiles')

        {
            'tree_home' => portage_home,
            'profiles_home' => profiles_home
        }
    end

    def self.get_tree_home
        SETTINGS['tree_home']
    end

    def self.get_profiles_home
        File.join(SETTINGS['tree_home'], 'profiles')
    end

    def self.get_db_home
        SETTINGS['db_home']
    end

    def self.get_log_home
        SETTINGS['log_home']
    end

    def self.get_portage_settings_home
        SETTINGS['settings_home']
    end

    def self.get_database
        Dir.glob(File.join(self.get_db_home, '*.sqlite')).sort.last
    end

    SETTINGS = Utils.get_settings unless $0.end_with?('01_generate_config.rb')

    Utils::OPTIONS = {
        "quiet" => true,
        "debug" => false,
        "db_filename" => defined?(SETTINGS) ? Utils.get_database : nil
    }
end

