#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

require 'thread'
require 'digest/md5'

module Portage3
    URL = 'druby://localhost'

    def self.get_uri(port)
        URL + ':' + port.to_s
    end
end

require 'common/client'
require 'common/database'
require 'common/logger'
require 'common/utils'

# TODO this is a temporary solution
require 'common/parser'

