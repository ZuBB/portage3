#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'nokogiri'
require 'fsobject'
require 'category_module'

module PackageModule
    include FSobject
    include CategoryModule

    # constants
    # name of the entity
    ENTITY = self.name.downcase[0..-7]
    # suffixes
    PROP_SUFFIXES = ['description', 'homepage', 'long_description']
    # sql stuff
    SQL = {
        'all' => 'select * from packages',
        'all@c_id' => 'select * from packages where category_id=?',
        'id' => <<-SQL
            SELECT id
            FROM packages
            WHERE package_name=? and category_id = ?
        SQL
    }

    def package_init(params)
        # fix ff
        params = Routines.fix_params(params, ENTITY != self.class.name.downcase)

        # create 'system' properties for repository (sub)object
        self.create_properties(
            ENTITY, Routines.get_module_suffixes() + PROP_SUFFIXES
        )

        # run inits for all kind of modules that we need to inherit
        self.gp_initialize(params)
        self.db_initialize(params)
        self.fs_initialize(params)

        # run init for category stuff
        self.category_init(params)
    end

    def package()
        @package ||= Database.get_1value(SQL["package"], package_id)
    end

    def package_id()
        @package_id ||= Database.get_1value(SQL['id'], [package, category_id])
    end

    def package_long_description()
        return @package_long_description ||= get_long_description()
    end

    def get_long_description()
        metadata_path = File.join(@package_home, "metadata.xml")

        if File.exists?(metadata_path) && File.readable?(metadata_path)
            xml_doc = Nokogiri::XML(IO.read(metadata_path))
            # TODO hardcoded 'en'
            description_node = xml_doc.xpath('//longdescription[@lang="en"]')
            description_node.inner_text.gsub(/\s+/, ' ')
        else
            '0_DESCRIPTION_DEF'
        end
    end

    def self.get_package_versions(atom)
        return EIX ? self.get_eix_versions(atom) : self.get_portage_versions(atom)
    end

    def self.get_eix_versions(atom)
        versions_line = %x[eix -x --end #{atom} | grep 'Available versions']

        # drop wording at start
        versions_line.sub!('Available versions:', '')

        # drop use flags
        versions_line.sub!(/\{[^\}]+\}\s*$/, "")

        # get versions and make it looks nice
        versions_line.strip().split(' ').map! { |version|
            version.sub!(/!.+/, '')
            version.gsub!(/\([^\)]+\)/, '')
            version.gsub!(/\[[^\]]+\]/, '')
            version.sub!(/\+[iv]$/, '')
            version.sub!(/[~*]+/, '')
            version
        }
    end

    def self.get_portage_versions(atom)
        # TODO fix this
        %x[#{File.dirname(__FILE__)}/../../bin/list_package_ebuilds.py #{atom}].split("\n").map { |line|
            line[atom.size + 1..-1]
        }
    end
end

