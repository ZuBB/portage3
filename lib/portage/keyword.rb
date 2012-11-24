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
        result = {}

        atom, arch = *line.split
        arch.strip! unless arch.nil?

        # take care about trailing ':'
        # it means slot for this atom/package
        result["slot"] = atom.slice!(/(?=:).+$/)[1..-1] if atom.include?(':')

        # take care about leading ~
        # it means match any subversion of the specified base version.
        if atom.start_with?('~')
            atom.sub!(/^~/, '')
            atom << '*' unless atom.end_with?('*')
        end

        # get version restrictions
        result["vrestr"] = atom.slice!(Atom::VERSION_RESTRICTION)

        # get versions
        unless (version = Atom.get_version(atom)).nil?
            result["version"] = version
            atom.sub!('-' + version, '')
        end

        unless arch.nil?
            arch.sub!(/\*$/, cur_arch) if arch.end_with?('*')
            arch.sub!(/^\*/, '-~') if arch.start_with?('*')
            arch, keyword = *(self.split_keywords(arch)[0])
            keyword.sub!(/^-~$/, 'stable')
        else
            keyword = 'unstable'
            arch = cur_arch
        end

        result['atom']    = atom 
        result['keyword'] = keyword 
        result['arch']    = arch 

        result
    end
end

