#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'repository_module'
require 'category_module'
require 'package_module'

class Package
    include PackageModule

    def initialize(params)
        # run init
        self.package_init(params)
    end

    def self.get_packages(params = {})
        packages = {}
        results = []

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
                packages[category_row[1]] = [] unless packages.has_key?(category_row[1])

                # get by pattern all packages are present in this category
                Dir.glob(File.join(category_home, '*/')).each do |package|
                    # strip common FS path at start
                    package = package.match(/\/([^\/]+)\/$/)[1]
                    # check if we miss this package
                    unless packages[category_row[1]].include?(package)
                        # and if so - add it
                        packages[category_row[1]] << package
                        results << {
                            'parent_dir' => category_home, 'value' => package
                        }
                    end
                end
            end
        end

        return results
    end
end

