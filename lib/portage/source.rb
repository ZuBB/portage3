#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Source
    SOURCES = [
        'portage tree',
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

