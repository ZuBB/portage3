#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'category_module'

class Category
    include CategoryModule

    def initialize(params)
        # run init
        self.category_init(params)
    end

    def self.get_categories(params = {})
        categories = self.get_canonical_categories(params)

        return categories.map do |category|
            { 'value' => category.first, 'parent_dir' => category.at(1) }
        end.sort do |a, b|
            a['value'] <=> b['value']
        end
    end

    def self.get_canonical_categories(params)
        # result here
        categories = []
        # name of the file with categories
        filename = File.join(params['profiles2_home'], 'categories')

        if File.exist?(filename)
            # process all lines
            IO.foreach(filename) do |line|
                # skip empty line, trim spaces and add it
                if line.match(/\S+/)
                    categories << [line.strip(), params['tree_home']]
                end
            end
        end

        # and finally
        return categories
    end

    def self.get_overlays_categories(params = {})
        # result here
        result = []

        # get all external repos and theirs info
        Database.db().execute(Repository::SQL['external']) do |repo_row|
            # get repo home
            repo_home = File.join(repo_row[2], repo_row[3] || repo_row[1])
            # skip if we do not have this repo
            next unless File.exist?(repo_home)
            # get by pattern all categories are present in this repo
            Dir.glob(File.join(repo_home, '*-*')).each do |category|
                # and strip common FS path at start
                category.sub!(repo_home + '/', '')
                # and strip common FS path at start
                result << [category, repo_home] if result.assoc(category).nil?
            end
        end
    end
end

