#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
module PProfile
    SQL = {
        '@' => 'SELECT name, id FROM profiles;',
        'names' => 'SELECT name from profiles;'
    }
    # find $(ls -d */ | grep -vE 'updates|desc') -type f -printf "%f\n" | sort -u
    FILES_WITH_ATOMS = [
        "package.keywords",
        "package.mask",
        "package.unmask",
        "package.provided",
        "package.use",
        "package.use.force",
        "package.use.mask",
        "package.use.stable.force",
        "package.use.stable.mask",
        "packages",
        "packages.build",
    ]

    def self.files_with_atoms(params)
        FILES_WITH_ATOMS.map { |filename|
            Dir[File.join(params['profiles_home'], "**/#{filename}")]
        }
        .flatten
        .reject { |item|
            File.exist?(File.join(File.dirname(item), 'deprecated'))
        }
    end
end

