#
# Generic Portage object lib
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'keyword'

module EmergeSearch
    PackageData = {
        "CATEGORY" => [],
        "PACKAGE" => [],
        "VERSIONS" => [],
        "HOMEPAGE" => [],
        "DESCRIPTION" => [],
        "LICENSE" => [],
        "keywords" => [],
        "mask_states" => []
    }
    TEMPLATE = <<TXTBLOCK
*  CATEGORY/PACKAGE
      Available versions: VERSIONS
      Installed versions: IVERSIONS
      Homepage:       HOMEPAGE
      Description:    DESCRIPTION
      License:        LICENSE\n
TXTBLOCK

    # case when we do search on name only
    QUERY_L1_V1 = <<-SQL
        SELECT
            p.id,
            c.name,
            p.name
        FROM packages p
        JOIN categories c ON c.id = p.category_id
        WHERE MAIN_PATTERN
        ORDER BY c.name, p.name ASC;
    SQL

    # case when we do search on name and on descr
    QUERY_L1_V2 = <<-SQL
        SELECT distinct
            p.id,
            c.name,
            p.name
        FROM ebuilds e
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        JOIN ebuild_descriptions ed ON ed.id = e.description_id
        WHERE MAIN_PATTERN
        ORDER BY c.name, p.name ASC;
    SQL

    # description
    QUERY_L2_DESCR = <<-SQL
        SELECT ed.descr
        FROM ebuild_descriptions ed
        JOIN ebuilds e ON ed.id = e.description_id
        WHERE e.package_id = ?
        LIMIT 1;
    SQL

    # homepages
    QUERY_L2_WWW = <<-SQL
        SELECT distinct eh.homepage
        FROM ebuild_homepages eh
        JOIN ebuilds_homepages ehs ON eh.id = ehs.homepage_id
        JOIN ebuilds e ON ehs.id = ehs.ebuild_id
        WHERE e.package_id = ?;
    SQL

    # licenses
    QUERY_L2_LICS = <<-SQL
        SELECT distinct l.name
        FROM licenses l
        JOIN license_spec_content lsc ON lsc.license_id = l.id
        JOIN license_specs ls ON ls.id = lsc.license_spec_id
        JOIN ebuilds_license_specs els ON els.license_spec_id = ls.id
        JOIN ebuilds e ON e.id = els.ebuild_id                    
        WHERE e.package_id = ?;
    SQL

    # case when we do search on name and on descr
    QUERY_L2_BASE = <<-SQL
        SELECT
            e.version,
            ek.keyword_id,
            em.state_id
        FROM ebuilds e
        JOIN ebuilds_keywords ek ON ek.ebuild_id=e.id
        LEFT JOIN ebuilds_masks em
            ON em.ebuild_id=e.id AND em.arch_id = ek.arch_id
        WHERE
            e.package_id = ? AND
            ek.arch_id = (
                SELECT value FROM system_settings WHERE param='arch'
            )
        ORDER BY e.version_order ASC;
    SQL

    def self.print_ebuild_specs(local_data)
        template = TEMPLATE.clone
        versions = []

        local_data['HOMEPAGE'].uniq!
        local_data['LICENSE'].uniq!

        local_data['VERSIONS'].each_index do |index|
            keyword = Keyword::SYMBOLS[local_data['keywords'][index] - 1]
            keyword = '(' + keyword + ')' if keyword.size > 0
            mask_state = local_data['mask_states'][index].nil? ? '' : '[M]'
            versions << keyword + local_data['VERSIONS'][index] + mask_state
        end

        local_data.keys.each do |key|
            next if key.match(/[[:lower:]]/)
            template.sub!(key, local_data[key].join(' '))
        end

        puts template
    end

    def self.prepare_sql_pattern!(pattern, regexp_pattern)
        return nil if pattern.nil?

        if regexp_pattern
            pattern.gsub!(/\.\*/, '%')
            pattern.gsub!(/\.\+/, '%')
            pattern.gsub!(/\\\./, '\\*')
            pattern.gsub!('.', '_')
            pattern.gsub!(/\\\*/, '\\.')
            pattern.gsub!(/%/, '!%')

            start_sub_pattern = /^\^/ =~ pattern ? ['^', ''] : [/^/, '%']
            pattern.sub!(*start_sub_pattern)
            end_sub_pattern = /\$$/ =~ pattern ? [/\$$/, ''] : [/$/, '%']
            pattern.sub!(*end_sub_pattern)
        else
            pattern = '%' + pattern + '%'
        end
    end

    def self.prepare_params(raw_pattern, also_desc)
        regexp_pattern = false
        category_pattern = nil
        condition = []
        result = []

        # drop quotes if present
        package_pattern = raw_pattern.sub(/^['"]?/, '').sub(/['"]?$/, '')

        # check if we have regexp
        if package_pattern.start_with?('%')
            regexp_pattern = true
            package_pattern.slice!(0)
        end

        # check if we have category pattern
        if package_pattern.include?('/')
            package_pattern.slice!(0)
            category_pattern = package_pattern.slice(0, pattern.index('/') - 1)
        end

        self.prepare_sql_pattern!(category_pattern, regexp_pattern)
        self.prepare_sql_pattern!(package_pattern, regexp_pattern)

        unless category_pattern.nil?
            operator = /[_%]/ =~ category_pattern ? 'like' : '='
            condition << "c.name #{operator} ? AND "
            result << category_pattern
        end

        operator = /[_%]/ =~ package_pattern ? 'like' : '='
        condition << "(p.name #{operator} ?"
        result << package_pattern

        if also_desc
            condition << " OR ed.descr #{operator} ?"
            result << package_pattern
        end

        condition << ')'
        sql_query = (also_desc ? QUERY_L1_V2 : QUERY_L1_V1).clone
        result.unshift(sql_query.sub('MAIN_PATTERN', condition.join(' ')))
    end

    def self.search(raw_pattern, flag = false)
        local_data = nil

        params = self.prepare_params(raw_pattern, flag)
        Database.select(*params).each do |prow|
            package_id = prow[0]
            local_data = PackageData.clone
            local_data['CATEGORY'] = [prow[1]]
            local_data['PACKAGE'] = [prow[2]]

            local_data['DESCRIPTION'] =
                Database.select(QUERY_L2_DESCR, package_id)

            local_data['HOMEPAGE'] =
                Database.select(QUERY_L2_WWW, package_id)

            local_data['LICENSE'] =
                Database.select(QUERY_L2_LICS, package_id)

            Database.select(QUERY_L2_BASE, package_id).each do |erow|
                local_data['VERSIONS'] << erow[0]
                local_data['keywords'] << erow[1]
                local_data['mask_states'] << erow[2]
            end

            self.print_ebuild_specs(local_data)
        end
    end

    def self.search_by_names(raw_pattern)
        self.search(raw_pattern)
    end

    def self.search_by_names8desc(raw_pattern)
        self.search(raw_pattern, true)
    end
end

