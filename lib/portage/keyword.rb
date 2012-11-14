#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
module Keyword
    LABELS = ['not work', 'not known', 'unstable', 'stable']
    SYMBOLS = ['-', '?', '~', '']
    SYM2LBL = Hash[SYMBOLS.zip(LABELS)]
    LBL2SYM = Hash[LABELS.zip(SYMBOLS)]
    SYM_RGXP = Regexp.new("^[#{SYMBOLS.join}]{0,2}")
    SQL = {
        '@1' => 'SELECT name, id FROM arches;',
        '@2' => 'SELECT name, id FROM keywords;',
        'pid' => 'SELECT id FROM ebuilds WHERE package_id=?',
        'ids@pid' => 'SELECT id FROM ebuilds WHERE package_id=?',
        'ids@pid&%v' => 'SELECT id FROM ebuilds WHERE package_id=? AND version like ?',
        'id@pid&v_co' => 'SELECT id FROM ebuilds WHERE package_id=? AND version OPERATOR ?',
        'pid' => <<-SQL
            SELECT p.id
            FROM packages p
            JOIN categories c on p.category_id=c.id
            WHERE c.name=? and p.name=?
        SQL
    }
    SQL2 = <<-SQL
        SELECT a.name FROM arches a
        JOIN system_settings st ON st.value=a.id
        WHERE param='arch';
    SQL
    SQL3 = <<-SQL
        SELECT k.name FROM keywords k
        JOIN system_settings st ON st.value=k.id
        WHERE param='keyword';
    SQL

    def self.pre_insert_task(source)
        result = {}
        sql_query = 'SELECT name, id FROM arches;'
        result['arches@id'] = Hash[Database.select(sql_query)]

        sql_query = 'SELECT name, id FROM keywords;'
        result['keywords@id'] = Hash[Database.select(sql_query)]

        sql_query = 'select id from sources where source=?;'
        result['sources@id'] = {
            source => Database.get_1value(sql_query, source)
        }

        result
    end

    def self.split_keywords(keywords)
        keywords.split.map do |keyword|
            sign = SYM_RGXP.match(keyword).to_s
            # TODO is '|| sign' a hack?
            [keyword.sub(sign, ''), SYM2LBL[sign] || sign]
        end
    end

    def self.parse_ebuild_keywords(keywords, all_arches)
        if keywords.include?('*')
            sign = keywords[keywords.index('*') - 1]

            if sign.nil?
                PLogger.error('We found keyword with \'*\' but without sign')
            end

            keywords.sub!(sign + '*', '')
            old_arches = keywords.split.map { |arch| arch.sub(SYM_RGXP, '') }
            rest_arches = (all_arches - old_arches).map { |arch|
                # NOTE for some reason I have to do '.dup' here
                arch.dup.insert(0, sign)
            }
            keywords += ' ' + rest_arches.join(' ')
        end

        self.split_keywords(keywords)
    end

    def self.parse_line(line, cur_arch, cur_keyword)
        atom = line.dup
        arch = atom.slice!(/\s+.*/)
        arch.strip! unless arch.nil?

        # take care about leading ~
        # it means match any subversion of the specified base version.
        atom.sub!(/^~/, '')
        slot = atom.slice!(atom.index(':')..-1)[1..-1] if atom.include?(':')

        # version restrictions
        atom.sub!(Utils::RESTRICTION, '')
        vrsn_rstr = $&

        # deal with versions
        atom.sub!(Utils::ATOM_VERSION, '')
        version = $&[1..-1] unless $&.empty?

        category, package = *atom.split('/')

        unless arch.nil?
            arch.sub!(/\*$/, cur_arch) if arch.end_with?('*')
            arch.sub!(/^\*/, '-~') if arch.start_with?('*')
            arch, keyword = *(self.split_keywords(arch)[0])
            keyword.sub!(/^-~$/, 'stable')
        else
            keyword = 'unstable'
            arch = cur_arch
        end

        result = {
            'vrsn_rstr' => vrsn_rstr,
            'category'  => category,
            'package'   => package,
            'version'   => version,
            'keyword'   => keyword,
            'arch'      => arch
        }
    end

    def self.get_package_id(atom_specs)
        params = [atom_specs['category'], atom_specs['package']]
        
        if (package_id = Database.get_1value(SQL["pid"], params)).nil?
            atom = "#{atom_specs['category']}/#{atom_specs['package']}"
            PLogger.warn("'#{atom}' package is not present in portage")
        end

        package_id
    end

    def self.get_ebuild_ids(atom_specs)
        if atom_specs['vrsn_rstr'].nil? && atom_specs['version'].nil?
            sql_query = SQL['ids@pid']
            params = [atom_specs['package_id']]
        elsif atom_specs['vrsn_rstr'] == '=' && atom_specs['version'].end_with?('*')
            sql_query = SQL['ids@pid&%v']
            params = [atom_specs['package_id'], atom_specs['version'].sub('*', '%')]
        else
            sql_query = SQL['id@pid&v_co']
            sql_query.sub!('OPERATOR', atom_specs['vrsn_rstr'])
            params = [atom_specs['package_id'], atom_specs['version']]
        end

        if (results = Database.select(sql_query, params).flatten).empty?
            PLogger.warn(
                "Atom (#{atom_specs["vrsn_rstr"]}"\
                "#{atom_specs['category']}/#{atom_specs['package']}"\
                "-#{atom_specs["version"]}) "\
                "already is not present in portage"
            )
        end

        results
    end
end

