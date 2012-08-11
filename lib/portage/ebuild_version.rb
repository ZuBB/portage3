#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
module EbuildVersion
    VER_REGEXP = Regexp.new("^(cvs\\.)?(\\d+)((\\.\\d+)*)([a-z]?)((_(pre|p|beta|alpha|rc)\\d*)*)(-r(\\d+))?$")
    SUFFIX_REGEXP = Regexp.new("^(alpha|beta|rc|pre|p)(\\d*)$")
    SUFFIX_VALUE = {"pre"=> -2, "p"=> 0, "alpha"=> -4, "beta"=> -3, "rc"=> -1}
    MAIN_CHECK = [
        {
            'message' => 'Next packages have zeros in `version_order` column',
            'sql_query' => <<-SQL
                select c.name, p.name, p.id
                from ebuilds e
                join packages p on e.package_id=p.id
                join categories c on p.category_id=c.id
                where version_order<1
                group by package_id;
            SQL
        },
        {
            'message' => 'Next packages have version_order > count(ebuild_id)',
            'sql_query' => <<-SQL
                select c.name, p.name, p.id
                from (
                    select
                        package_id,
                        count(package_id) as ebuilds,
                        max(version_order) as max_version_order
                    from ebuilds
                    group by package_id
                ) e
                join packages p on e.package_id=p.id
                join categories c on p.category_id=c.id
                where ebuilds!=max_version_order;
            SQL
        },
        {
            'message' => 'Next packages have dups in `version_order` per same package_id',
            'sql_query' => <<-SQL
                select c.name, p.name, p.id
                from (
                    select distinct package_id, count(id) as counter
                    from ebuilds
                    group by package_id, version_order
                    having counter > 1
                ) e
                join packages p on e.package_id=p.id
                join categories c on p.category_id=c.id;
            SQL
        }
    ]
    ALTERNATIVE_CHECK = [{
        'message' => "There are disparities in version orders for next packages",
        'sql_query' => <<-SQL
            select c.name, p.name, p.id
            from tmp_ebuild_versions e
            join packages p on e.package_id=p.id
            join categories c on p.category_id=c.id
            where
                version_order != version_order_SUFFIX and
                version_order_SUFFIX > 0
            group by package_id;
        SQL
    }]

    def self.get_data(params)
        tmp_results = {}

        Ebuild.get_ebuilds.each do |row|
            package_id = row[7]
            unless tmp_results.has_key?(package_id)
                tmp_results[package_id] = {
                    'category' => row[3],
                    'package'  => row[4],
                    'versions' => [],
                    'ids'      => []
                }
            end

            tmp_results[package_id]['versions'] << row[5]
            tmp_results[package_id]['ids'] << row[6]
        end

        tmp_results.values
    end

    def self.create_tmp_table
        sql_query = <<-SQL
            CREATE TABLE IF NOT EXISTS tmp_ebuild_versions (
                id INTEGER,
                ebuild_id INTEGER NOT NULL,
                package_id INTEGER NOT NULL,
                version VARCHAR NOT NULL,
                version_order INTEGER NOT NULL,
                version_order_eix INTEGER,
                version_order_api INTEGER,
                PRIMARY KEY (id)
            );
        SQL
        Database.execute(sql_query)

        sql_query = 'select count(id) from tmp_ebuild_versions'
        count = Database.get_1value(sql_query)

        if count == 0
            sql_query = <<-SQL
                insert into tmp_ebuild_versions
                (ebuild_id, package_id, version, version_order)
                select id, package_id, version, version_order
                from ebuilds;
            SQL
            Database.execute(sql_query)
        end
    end

    def self.sort_versions_with_eix(atom)
        pure_command = "eix --versionsort --exact --nocolor #{atom}"
        grep_command = 'grep \'Available versions\''
        versions_line = %x[#{pure_command} | #{grep_command}]

        # drop wording at start
        versions_line.sub!('Available versions:', '')

        # drop use flags
        versions_line.sub!(/\{\{[^\}]+\}\}\s*$/, "")

        # get versions and make it looks nice
        versions_line.strip.split(' ').map! { |version|
            version.sub!(/!.+/, '')
            version.gsub!(/\([^\)]+\)/, '')
            version.gsub!(/\[[^\]]+\]/, '')
            version.sub!(/\{tbz2\}$/, '')
            version.sub!(/\^[fmpbstuidP]{1,}$/, '')
            version.sub!(/\*[ilvs]{1,}$/, '')
            version.gsub!(/[~*]/, '')
            version
        }
    end

    def self.sort_versions_with_pyapi(versions)
        tool_path = '/../../bin/tools/sort_package_versions.pyapi.py'
        command = File.dirname(__FILE__) + tool_path + ' ' + versions
        %x[#{command}].strip.split(',')
    end

    # Ruby version of vercmp function from
    # /usr/lib/portage/pym/portage/versions.py
    def self.compare_versions_with_rbapi(ver1, ver2)
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

    def self.post_insert_check(checks, suffix = '')
        checks.each do |item|
            sql_query = item['sql_query'].sub('SUFFIX', suffix)
            results = Database.select(sql_query)
            PLogger.info("#{'-' * 72}")
            if results.size == 0
                PLogger.info("Passed")
            else
                PLogger.error(item['message'])
                results.each { |row|
                    PLogger.info("#{row[0]}/#{row[1]} (#{row[2]})")
                }
            end
        end
    end
end
