#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class PProfile
    SQL = {
        '@' => 'SELECT name, id FROM profiles;',
        'names' => 'SELECT name from profiles;'
    }
end

