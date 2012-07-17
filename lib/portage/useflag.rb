#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'dbobject'

class UseFlag
    include DBobject

    # constants
    # name of the entity
    ENTITY = self.name.downcase[0..-7]
    # suffixes
    PROP_SUFFIXES = ['name', 'description', 'type_id']
    # sql stuff
    SQL = {
        'type' => 'SELECT id FROM use_flag_types WHERE flag_type=?'
    }

    def initialize(params)
        p 'in Category::category_init'

        # fix ff
        params = Routines.fix_params(params, ENTITY != self.class.name.downcase)

        # create 'system' properties for repository (sub)object
        self.create_properties(ENTITY, Routines.get_module_suffixes() + PROP_SUFFIXES)

        # run inits for all kind of modules that we need to inherit
        self.gp_initialize(params)
        self.db_initialize(params)
    end

    def category()
        @category ||= Database.get_1value(SQL["category"], @category_id)
    end

    def category_id()
        @category_id ||= Database.get_1value(SQL["id"], @category)
    end

    def category_description()
        # smth
    end
end

