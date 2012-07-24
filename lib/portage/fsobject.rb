#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'dbobject'

module FSobject
    include DBobject
    PROP_SUFFIXES = ['fs', 'pd']

    def fs_initialize(params)
        self.vo_initialize(PROP_SUFFIXES, params, true)
    end
end

