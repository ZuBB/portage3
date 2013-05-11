#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
module Portage3::Profile
    SQL = {
        '@' => 'SELECT name, id FROM profiles;',
        '@2' => 'SELECT name, arch_id FROM profiles;',
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

    def self.process_profile_dirs(profile, targets)
        path = File.expand_path(File.join(Utils::get_profiles_home, profile))
        result = []

        if !File.exist?(path)
            #@logger.error("Path #{profile_path} does not exist")
            return result
        elsif !File.directory?(path)
            #@logger.error("Path #{profile_path} is not a dir")
            return result
        elsif File.exist?(File.join(path, 'deprecated'))
            return result
        end

        # we need to add base dir of profile also as source of data
        if File.size?(new_parent = File.join(path, 'parent'))
            IO.read(new_parent).lines.each do |relative_path|
                next if /^\s*#/ =~ relative_path
                next if /^\s*$/ =~ relative_path
                relative_path.strip!

                result.concat(self.process_profile_dirs(
                    File.join(profile, relative_path), targets))
            end
        end

        targets.each { |target|
            target_file = File.join(path, target)
            result << target_file if File.size?(target_file)
        }

        result
    end
end

