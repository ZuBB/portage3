#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'nokogiri'
require 'category'

class Package < Category
    ENTITY = self.name.downcase
    PROP_SUFFIXES = ['description', 'ldescription']
    SQL = {
        'all' => 'select * from packages',
        'all@c_id' => 'select * from packages where category_id=?',
        'id' => 'SELECT id FROM packages WHERE name=? and category_id = ?',
        '@' => 'SELECT name, id FROM packages;',
        'ghost' => <<-SQL
            SELECT distinct package, category_id
            FROM TMP_TABLE tp
            WHERE NOT EXISTS (
                SELECT name FROM packages p WHERE p.name = tp.package
            );
        SQL
    }

    def initialize(params)
        super(params)

        @cur_entity = ENTITY
        create_properties(PROP_SUFFIXES)
        gp_initialize(params)
        db_initialize(params)
    end

    def package()
        @package ||= Database.get_1value(SQL["package"], package_id)
    end

    def package_id()
        @package_id ||= Database.get_1value(SQL['id'], package, category_id)
    end

    def package_home()
        File.join(category_home, package)
    end

    def package_long_desc()
        return @package_ldescription unless @package_ldescription.nil?

        metadata_path = File.join(package_home, "metadata.xml")

        if File.exists?(metadata_path) && File.readable?(metadata_path)
            xml_doc = Nokogiri::XML(IO.read(metadata_path))
            # TODO hardcoded 'en'
            description_node = xml_doc.xpath('//longdescription[@lang="en"]')
            ldescription = description_node.inner_text.gsub(/\s+/, ' ')
        else
            ldescription = '0_DESCRIPTION_DEF'
        end

        @package_ldescription = ldescription
    end

    def self.get_packages(params = {})
        results = {}
        categories = Database.select(Category::SQL['all'])

        Database.select(Repository::SQL['all']).each do |repo_row|
            repo_home = File.join(repo_row[2], repo_row[3] || repo_row[1])
            next unless File.exist?(repo_home)

            categories.each do |category_row|
                category = category_row[1]
                category_home = File.join(repo_home, category)
                next unless File.exist?(category_home)

                Dir.entries(category_home).each do |package|
                    next if ['.', '..'].include?(package)
                    next unless File.directory?(File.join(category_home, package))

                    atom = category + '/' + package
                    unless results.has_key?(atom)
                        results[atom] = {
                            'package' => package,
                            'category' => category,
                            'category_id' => category_row[0],
                            'repository' => repo_row[1],
                            'repository_pd' => repo_row[2],
                            'repository_fs' => repo_row[3] || repo_row[1]
                        }
                    end
                end
            end
        end

        results.values
    end
end

