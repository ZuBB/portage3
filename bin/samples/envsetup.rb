#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/01/12
# Latest Modification: Vasyl Zuzyak, ...
#

module EnvSetup
    PATH2ROOT = '../..'
    BASEDIR = File.dirname(__FILE__)

    def self.get_path2lib(basedir = BASEDIR)
        File.expand_path(File.join(basedir, PATH2ROOT, 'lib'))
    end

    def self.get_lib_dirs
        Dir[File.join(self.get_path2lib, '*')].delete_if { |item| 
            File.file?(item)
        }
    end
end

EnvSetup.get_lib_dirs.each { |libdir|
    $:.push File.expand_path(libdir)
}

require 'optparse'
require 'database'
require 'utils'
#require 'plogger'

