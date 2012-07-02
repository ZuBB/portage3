#
# Generic Portage object lib
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'routines'

module GPobject
    include Routines
    PROP_SUFFIXES = [nil]

    def gp_initialize(params)
        # check if everything is OK
        unless process_value(params)
            throw "GPobject: can not verify `#{params['value']}` value"
        end
    end

    # check and assing passed value
    def process_value(params)
        value = params['value']
        # TODO: some checks for non latin chars etc
        if value.is_a?(String) && !value.empty? && !Utils.is_number?(value)
            self.set_prop(value)
        end

        return true
    end
end

