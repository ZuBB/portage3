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
    def create_properties(entity, suffixes = [nil])
        @cur_entity = entity

        suffixes.each do |suffix|
            property_name = @cur_entity.dup()
            property_name += ('_' + suffix) if suffix.is_a?(String)
            self.set_prop(nil, suffix)

            # temporary commented out
            #self.class.send(
                #:define_method,
                #property_name.to_sym,
                #Proc.new { instance_variable_get('@' + property_name) }
            #)
            #end
        end
    end

    # gets a value of the instance property
    def get_prop_name(suffix = nil, entity = nil)
        prop_name = (entity || @cur_entity).dup

        unless prop_name.empty?
            prop_name += ('_' + suffix) if suffix.is_a?(String)
            return '@' + prop_name
        end

        return nil
    end

    # sets a value of the instance property
    def set_prop(value = nil, suffix = nil, entity = nil)
        prop_name = (entity || @cur_entity).dup

        unless prop_name.empty?
            prop_name += ('_' + suffix) if suffix.is_a?(String)
            self.instance_variable_set('@' + prop_name, value)
        end
    end

    # gets a value of the instance property
    def get_prop(suffix = nil, entity = nil)
        prop_name = (entity || @cur_entity).dup

        unless prop_name.empty?
            prop_name += ('_' + suffix) if suffix.is_a?(String)
            self.instance_variable_get('@' + prop_name)
        end
    end

    # gets a refernce to the class by entity (its downcase name)
    def get_class(entity)
        Object.const_get((entity || @cur_entity).dup().capitalize())
    end

    # gets an array of all suffixes that are defined in modules
    def self.get_module_suffixes()
        # lets filter objects that
        # * are modules
        # * theirs name ends with 'object'
        # * theirs name starts with 2 upcase letters
        Object.constants.select do |const|
            (Kernel.const_get(const) rescue nil).is_a?(Module) &&
            const.end_with?('object') &&
            const.match(/^[A-Z]{2}/).nil? == false
        # get PROP_SUFFIXES constant from filtered modules
        end.map { |module_name|
            Kernel.const_get(module_name).const_get('PROP_SUFFIXES'.to_sym)
        }.flatten
    end

    # moves all props of 'value' hash outside
    def self.fix_params(params, trim_fs_path, preserve_fs = false)
        if params['value'].is_a?(Hash)
            value = params['value']['value']
            fsvalue = params['value']['fsvalue']
            parent_dir = params['value']['parent_dir']
        end

        if trim_fs_path
            parent_dir ||= params['parent_dir']
            fsvalue = parent_dir.match(/[^\/]+$/).to_s
            parent_dir = parent_dir[0..-(fsvalue.size + 2)]
            value = nil

            if !preserve_fs
                value = fsvalue
                fsvalue = nil
            end
        end

        if !defined?(parent_dir).nil?
            params['parent_dir'] = parent_dir
            params['fsvalue'] = fsvalue
            params['value'] = value
        end

        return params
    end
end

