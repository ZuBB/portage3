#
# Generic Portage object lib
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'routines'

module GPobject
    include Routines
    PROP_SUFFIXES = ['']

    def gp_initialize(params)
        self.vo_initialize(PROP_SUFFIXES, params, true)
    end
end

