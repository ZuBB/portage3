#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Setting
    SQL = {
        '@' => 'select param, value from system_settings;'
    }
end

