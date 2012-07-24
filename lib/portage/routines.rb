#
# Generic Portage object lib
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
module Routines
    # creates instance properties that is related to all included modules
    # eg `Repository.new` was called. Next properties will be created
    #  * 'repository' from GPobject
    #  * 'repository_id' from DBobject
    #  * 'repository_fs' from FSobject
    #  * 'repository_pd' from FSobject
    #  * anything else that was defined directly in Repository
    def create_properties(suffixes = [])
        suffixes.map do |suffix|
            @cur_entity + (suffix.empty?() ? '': '_' + suffix)
        end
    end

    # TODO check for improvements (repository || repository_id)
    def vo_initialize(suffixes, params, throw_allowed = false)
        self.create_properties(suffixes).each do |prop_name|
            value = params[prop_name]
            unless value.nil?
                self.instance_variable_set('@' + prop_name, value)
            else
                throw "can not find `#{prop_name}` in params" if throw_allowed
            end
        end
    end
end

