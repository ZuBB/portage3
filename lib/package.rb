#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'category' unless Object.const_defined?(:Category)

class Package < Category
    PACKAGE_ID_SQL = <<SQL
SELECT packages.id
FROM packages, categories
WHERE
    categories.category_name=? and
    packages.package_name=? and
    packages.category_id = categories.id
SQL

    def initialize(params)
        # call init of superclass
        super(params)

        # assign some default values
        @PACKAGE = params["package"]
        @package_home = File.join(@category_home, @PACKAGE)

        # check if everything is OK
        unless File.exist?(@package_home) && File.directory?(@package_home)
            throw "Can not access package #{@PACKAGE} home dir"
        end

        # assign some default values
        @method = params["method"] == "portageq" ? "portageq" : "parse"
        @package_description = nil
        @package_homepage = nil
        @long_description = nil
        @package_id = nil
    end

    def package_description()
        return @package_description ||= get_package_description()
    end

    def package_homepage()
        return @package_homepage ||= get_package_homepage()
    end

    def long_description()
        return @long_description ||= get_long_description()
    end

    def package_id()
        return @package_id ||= get_package_id()
    end

    def package()
        return @PACKAGE
    end

    private
    def get_package_description()
        create_ebuild_instance.description()
    end

    def get_package_homepage()
        create_ebuild_instance.homepage()
    end

    def get_package_id()
        Database.get_1value(PACKAGE_ID_SQL, [@CATEGORY, @PACKAGE])
    end

    def get_long_description()
        metadata_path = File.join(@package_home, "metadata.xml")

        if File.exists?(metadata_path) && File.readable?(metadata_path)
            xml_doc = Nokogiri::XML(IO.read(metadata_path))
            # TODO hardcoded 'en'
            description_node = xml_doc.xpath('//longdescription[@lang="en"]')
            description_node.inner_text.gsub(/\s+/, ' ')
        else
            '0_DESCRIPTION_DEF'
        end
    end

    def create_ebuild_instance()
        require 'ebuild' unless Object.const_defined?(:Ebuild)
        filename = Dir.glob(File.join(@package_home, '*.ebuild')).sort.first
        Ebuild.new({
            "portage_home" => @portage_home,
            "category" => @CATEGORY,
            "package" => @PACKAGE,
            "filename" => filename,
            "method" => @method
        }, false)
    end
end
