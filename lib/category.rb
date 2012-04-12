#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'nokogiri' unless Object.const_defined?(:Nokogiri)

class Category
    CATEGORY_ID_SQL = "SELECT id FROM categories WHERE category_name=?;"

    def initialize(params)
        # assign some default values
        @CATEGORY = params["category"]
        @portage_home = params["portage_home"]
        @category_home = File.join(@portage_home, @CATEGORY)

        # check if everything is OK
        unless File.exist?(@category_home) && File.directory?(@category_home)
            throw "Can not access category #{@CATEGORY} home dir"
        end

        # assign some default values
        @category_description = nil
        @category_id = nil
    end

    def category_description()
        return @category_description ||= get_category_description()
    end

    def category_id()
        return @category_id ||= get_category_id()
    end

    def category()
        return @CATEGORY
    end

    private
    def get_category_description()
        metadata_path = File.join(@category_home, "metadata.xml")

        if File.exists?(metadata_path) && File.readable?(metadata_path)
            xml_doc = Nokogiri::XML(IO.read(metadata_path))
            # TODO hardcoded 'en'
            xpath = '//longdescription[@lang="en"]'
            xml_doc.xpath(xpath).inner_text.gsub(/\s+/, ' ').strip()
        else
            '0_DESCRIPTION_DEF'
        end
    end

    def get_category_id()
        Database.get_1value(CATEGORY_ID_SQL, [@CATEGORY])
    end
end
