#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'nokogiri'
require 'repository'

class Category < Repository
    ENTITY = self.name.downcase
    PROP_SUFFIXES = ['description']
    SQL = {
        'category' => 'SELECT name FROM categories WHERE id=?',
        'id' => 'SELECT id FROM categories WHERE name=?',
        'all' => 'SELECT * FROM categories'
    }

    def initialize(params)
        super(params)

        @cur_entity = ENTITY
        create_properties(PROP_SUFFIXES)
        gp_initialize(params)
        db_initialize(params)
    end

    def category()
        @category ||= Database.get_1value(SQL["category"], @category_id)
    end

    def category_id()
        @category_id ||= Database.get_1value(SQL["id"], @category)
    end

    def category_home()
        File.join(repository_home, category)
    end

    def category_description()
        return @category_description unless @category_description.nil?

        metadata_path = File.join(category_home, "metadata.xml")

        if File.exists?(metadata_path) && File.readable?(metadata_path)
            xml_doc = Nokogiri::XML(IO.read(metadata_path))
            @category_description = xml_doc.
                # TODO hardcoded 'en'
                xpath('//longdescription[@lang="en"]').
                inner_text.gsub(/\s+/, ' ').strip()
        else
            @category_description = '0_DESCRIPTION_DEF'
        end

        @category_description
    end

    def self.get_categories(params = {})
        results = {}

        Database.select(Repository::SQL['all']).each do |repo_row|
            repo_home = File.join(repo_row[2], repo_row[3] || repo_row[1])

            next unless File.exist?(repo_home)
            next unless (filename = File.join(repo_home, 'profiles', 'categories'))

            IO.read(filename).split("\n").each do |line|
                next if (category = line.strip).empty?
                unless results.has_key?(category)
                    results[category] = {
                        'category' => category,
                        'repository' => repo_row[1],
                        'repository_pd' => repo_row[2],
                        'repository_fs' => repo_row[3] || repo_row[1]
                    }
                end
            end
        end

        results.values
    end
end

