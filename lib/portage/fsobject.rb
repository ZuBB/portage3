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
        # check if everything is OK
        unless process_fs_object(params)
            throw "FSobject: can not access `#{params['value']}` FS object"
        end
    end

    def process_fs_object(params)
        return true if check_by_entity_id()
        return true if check_by_fs(params)

        return false
    end

    def check_by_entity_id()
        entity_id_value = get_prop(DBobject::PROP_SUFFIXES[0])

        unless entity_id_value.nil?
            sql_query = get_class()::SQL[@cur_entity]
            value = Database.get_1value(sql_query, entity_id_value)
            unless value.nil?
                set_prop(value[2], PROP_SUFFIXES[1])
                set_prop(value[3], PROP_SUFFIXES[0])
                return true
            end
        end

        return false
    end

    def check_by_fs(params)
        fsvalue = params['fsvalue'] || params['value']
        target = File.join(params['parent_dir'], fsvalue)

        # target should exist in FS
        return false unless File.exist?(target)
        # target should be a file if we process ebuild
        return false if File.directory?(target) && @cur_entity == 'ebuild'
        # target should not be a file if we process anything except ebuild
        return false if File.file?(target) && @cur_entity != 'ebuild'

        self.set_prop(fsvalue, PROP_SUFFIXES[0])
        self.set_prop(params['parent_dir'], PROP_SUFFIXES[1])

        return true
    end
end

