#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Source
    SOURCES = [
        'ebuilds',
        'profiles',
        'make.conf',
        '/etc/portage',
        'CLI',
        '/var/db/pkg'
    ]
    SQL = {
        '@' => 'select source, id from sources;'
    }
end

