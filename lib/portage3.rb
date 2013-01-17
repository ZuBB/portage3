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

require 'common/database'
require 'common/logger'
require 'common/utils'

# TODO this is a temporary solution
require 'common/parser'
