#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/01/12
# Latest Modification: Vasyl Zuzyak, ...
#

module EnvSetup
    def self.get_path2root
        '../..'
    end

    def self.get_path2lib(basedir = File.dirname(__FILE__))
        path_parts = [basedir, self.get_path2root, 'lib']
        File.expand_path(File.join(*path_parts))
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

require 'utils'
