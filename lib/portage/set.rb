#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Portage3::Set
    SQL = {
        '@' => 'SELECT name, id FROM sets;'
    }

    SETS = [
        'system',
        'world',
        'installed'
    ]
end

