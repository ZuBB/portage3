#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'gpobject'

module DBobject
    include GPobject

    PROP_SUFFIXES = ['id']

    def db_initialize(params)
        self.vo_initialize(PROP_SUFFIXES, params)
    end
end

