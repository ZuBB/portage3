#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

require 'thread'
require 'digest/md5'

module Portage3
    def self.settings_home
        old_path = '/etc/make.conf'
        new_path = '/etc/portage/make.conf'

        return old_path if File.exist?(old_path)
        return new_path if File.exist?(new_path)
    end
end

Thread.abort_on_exception = true

require 'common/database'
require 'common/logger'
require 'common/utils'

# TODO this is a temporary solution
require 'common/parser'
