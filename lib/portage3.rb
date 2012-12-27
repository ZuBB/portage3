#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

require 'thread'
require 'digest/md5'

module Portage3
    # TODO fill this module
end

Thread.abort_on_exception = true

require 'common/server'
require 'common/client'
require 'common/database'
require 'common/logger'
require 'common/utils'

# TODO this is a temporary solution
require 'common/parser'

