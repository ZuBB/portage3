#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/03/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'ebuild_module'

class Ebuild
    include EbuildModule

    def initialize(params, strict = true)
        # run init
        self.ebuild_init(params)
    end

    def self.get_ebuilds(params = {})
        #return [{
            #'value' => "dasher-4.11.ebuild",
            #'parent_dir' => "/usr/portage/app-accessibility/dasher"
            #'value' => "speech-tools-1.2.96_beta.ebuild",
            #'parent_dir' => "/usr/portage/app-accessibility/speech-tools"
        #}]

        ebuilds = []

        # get all repos and theirs info
        Database.select(RepositoryModule::SQL['all']).each do |repo_row|
            # get repo home
            repo_home = File.join(repo_row[2], repo_row[3] || repo_row[1])
            # skip if we do not have this repo
            next unless File.exist?(repo_home)

            Database.select(CategoryModule::SQL['all']).each do |category_row|
                # get category home
                category_home = File.join(repo_home, category_row[1])
                # skip if we do not have this repo
                next unless File.exist?(category_home)

                Database.select(PackageModule::SQL['all@c_id'], category_row[0]).each do |package_row|
                    # get category home
                    package_home = File.join(category_home, package_row[2])
                    # skip if we do not have this repo
                    next unless File.exist?(package_home)

                    # get by pattern all ebuilds are present in this category
                    Dir.glob(File.join(package_home, '*ebuild')).each do |ebuild|
                        ebuilds << [ebuild.sub!(package_home + '/', ''), package_home]
                    end
                end
            end
        end

        # and finally
        return ebuilds.map { |ebuild|
            { 'value' => ebuild.first, 'parent_dir' => ebuild.last }
        }
    end
end

