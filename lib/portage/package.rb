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
        'id' => 'SELECT id FROM packages WHERE package_name=? and category_id = ?'
    }
    VER_REGEXP = Regexp.new("^(cvs\\.)?(\\d+)((\\.\\d+)*)([a-z]?)((_(pre|p|beta|alpha|rc)\\d*)*)(-r(\\d+))?$")
    SUFFIX_REGEXP = Regexp.new("^(alpha|beta|rc|pre|p)(\\d*)$")
    SUFFIX_VALUE = {"pre"=> -2, "p"=> 0, "alpha"=> -4, "beta"=> -3, "rc"=> -1}

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

	# Ruby version of vercmp function from
	# /usr/lib/portage/pym/portage/versions.py
    def self.vercmp(ver1, ver2)
        if ver1 == ver2
            return 0
        end

        match1 = ver1.match(VER_REGEXP)
        match2 = ver2.match(VER_REGEXP)

        # checking that the versions are valid
        return nil unless match1
        return nil unless match2

        # shortcut for cvs ebuilds (new style)
        if match1[1] && !match2[1]
            return 1
        elsif match2[1] && !match1[1]
            return -1
        end

        # building lists of the version parts before the suffix
        # first part is simple
        list1 = [match1[2].to_i]
        list2 = [match2[2].to_i]

        # this part would greatly benefit from a fixed-length version pattern
        if match1[3] || match2[3]
            vlist1 = match1[3].to_s[1..-1].split(".") rescue ''
            vlist2 = match2[3].to_s[1..-1].split(".") rescue ''

            for i in 0...[vlist1.size, vlist2.size].max
                # Implcit .0 is given a value of -1, so that 1.0.0 > 1.0, since it
                # would be ambiguous if two versions that aren't literally equal
                # are given the same value (in sorting, for example).
                if vlist1.size <= i || vlist1[i].size == 0
                    list1.push(-1)
                    list2.push(vlist2[i].to_i)
                elsif vlist2.size <= i || vlist2[i].size == 0
                    list1.push(vlist1[i].to_i)
                    list2.push(-1)
                    # Let's make life easy and use integers unless we're forced to use floats
                elsif (vlist1[i][0] != "0" && vlist2[i][0] != "0")
                    list1.push(vlist1[i].to_i)
                    list2.push(vlist2[i].to_i)
                    # now we have to use floats so 1.02 compares correctly against 1.1
                else
                    # list1.append(float("0."+vlist1[i]))
                    # list2.append(float("0."+vlist2[i]))
                    # Since python floats have limited range, we multiply both
                    # floating point representations by a constant so that they are
                    # transformed into whole numbers. This allows the practically
                    # infinite range of a python int to be exploited. The
                    # multiplication is done by padding both literal strings with
                    # zeros as necessary to ensure equal length.
                    max_len = [vlist1[i].size, vlist2[i].size].max
                    list1.push(vlist1[i].ljust(max_len, "0").to_i)
                    list2.push(vlist2[i].ljust(max_len, "0").to_i)
                end
            end
        end

        # and now the final letter
        # NOTE: Behavior changed in r2309 (between portage-2.0.x and portage-2.1).
        # The new behavior is 12.2.5 > 12.2b which, depending on how you look at,
        # may seem counter-intuitive. However, if you really think about it, it
        # seems like it's probably safe to assume that this is the behavior that
        # is intended by anyone who would use versions such as these.
        if match1[5].size > 0
            list1.push(match1[5].ord)
        end

        if match2[5].size > 0
            list2.push(match2[5].ord)
        end

        for i in 0...[list1.size, list2.size].max
            if list1.size <= i
                return -1
            elsif list2.size <= i
                return 1
            elsif list1[i] != list2[i]
                a = list1[i]
                b = list2[i]
                return a - b
            end
        end

        # main version is equal, so now compare the _suffix part
        list1 = match1[6].split("_")[1..-1]
        list2 = match2[6].split("_")[1..-1]

        for i in 0...[list1.to_s.size, list2.to_s.size].max
            # Implicit _p0 is given a value of -1, so that 1 < 1_p0
            if list1.nil? || list1[i].nil?
                s1 = ["p","-1"]
            else
                s1 = SUFFIX_REGEXP.match(list1[i]).to_a.drop(1)
            end

            if list2.nil? || list2[i].nil?
                s2 = ["p","-1"]
            else
                s2 = SUFFIX_REGEXP.match(list2[i]).to_a.drop(1)
            end

            if s1[0] != s2[0]
                a = SUFFIX_VALUE[s1[0]]
                b = SUFFIX_VALUE[s2[0]]
                rval = a - b
                return rval
            end

            if s1[1] != s2[1]
                # it's possible that the s(1|2)[1] == ''
                # in such a case, fudge it.
                begin
                    r1 = s1[1].to_i
                rescue
                    r1 = 0
                end

                begin
                    r2 = s2[1].to_i
                rescue
                    r2 = 0
                end

                if (rval = (r1 - r2))
                    return rval
                end
            end
        end

        # the suffix part is equal to, so finally check the revision
        if !match1[10].nil? && match1[10].size > 0
            r1 = match1[10].to_i
        else
            r1 = 0
        end

        if !match2[10].nil? && match2[10].size > 0
            r2 = match2[10].to_i
        else
            r2 = 0
        end

        rval = (r1 - r2)
        return rval
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

