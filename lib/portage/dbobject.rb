#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'gpobject'
require 'utils'

module DBobject
    include GPobject

    PROP_SUFFIXES = ['id']

    def db_initialize(params)
        # check if everything is OK
        unless process_db_value(params)
            throw "DBobject: can not find #{params['value']} in db"
        end
    end

    # check and assing passed value
    def process_db_value(params)
        if Utils.is_number?(params['value'])
            sql_query = get_class()::SQL[@cur_entity]
            value = params['value'].to_i

            return false if Database.get_1value(sql_query, value).nil?
            self.set_prop(value, DBobject::PROP_SUFFIXES[0])
        end

        return true
    end
end

