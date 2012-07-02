#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'nokogiri'
require 'fsobject'

module CategoryModule
    include FSobject

    # constants
    # name of the entity
    ENTITY = self.name.downcase[0..-7]
    # suffixes
    PROP_SUFFIXES = ['description']
    # sql stuff
    SQL = {
        'category' => 'SELECT category_name FROM categories WHERE id=?',
        'id' => 'SELECT id FROM categories WHERE category_name=?',
        'all' => 'SELECT * FROM categories'
    }

    def category_init(params)
        # fix ff
        params = Routines.fix_params(params, ENTITY != self.class.name.downcase)

        # create 'system' properties for repository (sub)object
        self.create_properties(ENTITY, Routines.get_module_suffixes() + PROP_SUFFIXES)

        # run inits for all kind of modules that we need to inherit
        self.gp_initialize(params)
        self.db_initialize(params)
        self.fs_initialize(params)
    end

    def category()
        @category ||= Database.get_1value(SQL["category"], @category_id)
    end

    def category_id()
        @category_id ||= Database.get_1value(SQL["id"], @category)
    end

    def category_description()
        return @category_description unless @category_description.nil?

        metadata_path = File.join(home(), "metadata.xml")

        if File.exists?(metadata_path) && File.readable?(metadata_path)
            xml_doc = Nokogiri::XML(IO.read(metadata_path))
            @category_description = xml_doc.
                # TODO hardcoded 'en'
                xpath('//longdescription[@lang="en"]').
                inner_text.gsub(/\s+/, ' ').strip()
        else
            @category_description = '0_DESCRIPTION_DEF'
        end

        return @category_description
    end

    def home()
        File.join(@category_pd, @category)
    end
end

