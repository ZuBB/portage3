#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#

require 'thread'
require 'digest/md5'

module Portage3
    OLD_PATH = '/etc/make.conf'
    NEW_PATH = '/etc/portage/make.conf'

    def self.settings_home
        return self::OLD_PATH if File.exist?(self::OLD_PATH)
        return self::NEW_PATH if File.exist?(self::NEW_PATH)
        return nil
    end

    def self.portage_settings_home
        Utils.get_portage_settings_home
    end

    def self.package_asterisk_content(file)
        filename = File.join(self.portage_settings_home, file)
        results = []

        if File.exist?(filename)
            if File.file?(filename)
                results = IO.readlines(filename)
            elsif File.exist?(filename) && File.directory?(filename)
                Dir[File.join(filename, '**/*')].each { |file|
                    results += IO.readlines(filename) if File.size?
                }
            end
        end

        results
    end
end

Thread.abort_on_exception = true

# common stuff
require 'common/database'
require 'common/logger'
require 'common/utils'
# TODO this is a temporary solution
require 'common/parser'

# portage modules
require 'portage/source'
require 'portage/atom'
require 'portage/profile'
