#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 12/12/11
# Latest Modification: Ronen Botzer, 12/15/11
#
require 'time' unless Object.const_defined?(:Time)

TIMESTAMP = "%Y%m%d-%H%M%S"
STORAGE = {
    :home_folder => 'portage3_data',
    :portage_home => 'portage',
    :required_space => 700,
    :root => '/dev/shm'
}

def get_timestamp()
    return Time.now.strftime(TIMESTAMP)
end

