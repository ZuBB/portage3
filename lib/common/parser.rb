#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/01/12
# Latest Modification: Vasyl Zuzyak, ...
#

module Parser
    SUB_VALUE = Regexp.new("(\\$\\{([\\w_]+)\\})", Regexp::IGNORECASE)
    MTIME_REGEXP = Regexp.new("\\d{4}\\/\\d\\d\\/\\d\\d \\d\\d:\\d\\d:\\d\\d")
    AUTHOR_REGEXP = Regexp.new(":\\d\\d ([\\w_\\-\\.]+) Exp \\$$")

    def self.get_value_from_cvs_header(file_content, keyword)
        const = nil

        self.constants.each do |constant|
            if constant.downcase.to_s.include?(keyword)
                const = self.const_get(constant)
                break
            end
        end

        return  "0_" + keyword.upcase + "_REGEXP_DEF" if const.nil?

        file_content.each { |line|
            if line.start_with?('# $Header:')
                match = const.match(line)
                if match.nil?
                    return  "X_" + keyword.upcase + "_REGEXP"
                else
                    return (match[1] || match).to_s 
                end
            end
        }

        return  "0_" + keyword.upcase + "_DEF"
    end

    def self.get_value1(line)
        # get value
        value = line.split('=', 2)[1] || ''
        # strip spaces at start
        value.lstrip!
        # get quote char
        #quote = (value.slice(0)).chr rescue ''
        quote = value[0].chr rescue ''
        if quote && (quote == '"' || quote == '\'')
            # strip quotes at start
            #pattern = Regexp.new("((\\" + quote + "|[^" + quote + "])*)" + quote)
            pattern = Regexp.new(quote + "([^" + quote + "]*)" + quote)
            # strip quotes at start
            pattern.match(value)[1].strip rescue ''
        elsif value.size > 1
            value.sub(/\s+#.*$/, '').strip
        else
            quote
        end
    end

    def self.extract_sub_value(file_content, result, patterns)
        if result.include?("${")
            sub_values_match = result.scan(SUB_VALUE)
            while sub_values_match.empty? == false
                value = patterns.has_key?(sub_values_match[0][1]) ?
                    patterns[sub_values_match[0][1]] :
                    get_multi_line_ini_value(
                        file_content, sub_values_match[0][1]
                    )

                unless value.end_with?("_DEF")
                    result.sub!(sub_values_match[0][0], value)
                end

                # drop out first item
                sub_values_match.shift()
            end
        end

        return result
    end

    def self.find_lines_with_keyword(file_content, keyword)
        # TODO check if 'each' can be replaced with 'select'
        # array with lines that have keyword in it
        results = []

        file_content.each do |line|
            # if this is commented line, go next
            next if line.match(/^\s*#/)

            # if line does not have keyword, go next
            next unless line.include?(keyword)

            # if line does not have '=', go next
            next unless line.include?('=')

            # if line has NON_KEYWORD_VAR but not a KEYWORD, go next
            next if Regexp.new("\\b" + keyword + "\\s*=").match(line).nil?

            # if '=' is before keyword, go next
            next if line.index(keyword) > line.index('=')

            if
                # case when keyword at 1st position, '#' not present
                (line.index(keyword) == 0 && !line.include?('#')) ||
                # case when '#' is present but after '='
                (line.include?('#') && line.index('=') + 1 < line.index('#')) ||
                # case when space chars are before keyword
                (Regexp.new("^\\S+" + keyword).match(line).nil?)
                    results << line
            end
        end

        return results
    end

    def self.get_multi_line_ini_value(file_content, keyword)
        lines = find_lines_with_keyword(file_content, keyword)
        result = ''

        if lines.size == 1
            # if there is (') or (") at the end of string ...
            if lines[0].match(/[^=]["']$/) || keyword == 'EAPI'
                # ... lets get value
                result = get_value1(lines[0])
                # ... and delete that line from source
                file_content.delete_at(file_content.index(lines[0]))
            # else this should be multiline case
            else
                lines2delete = []
                index = file_content.index(lines[0]) - 1

                begin
                    lines2delete << (index += 1)
                    line = file_content[index]
                    result << "\n" + line

                    checks = []
                    # TODO: this is checked in 1 line case
                    # Do we need this here?
                    # got final quote at the end of line
                    checks << line.match(/[^=]["']\n$/).nil?
                    # got final quote at the start of line
                    checks << line.match(/^["']\n$/).nil?
                    # got EOF
                    checks << (index + 1 != file_content.size())
                    # got new variable at the next line
                    next_line = file_content[index + 1]
                    checks << next_line.match(/^[A-Z_]+=/).nil? if next_line
                    # got next line that is empty
                    checks << next_line.match(/^\n$/).nil? if next_line
                end while !checks.include?(false)

                lines2delete.each { |index| file_content.delete_at(index) }
                result.gsub!(/[\\\n]+/, ' ')

                result = get_value1(result)
            end
        elsif lines.size > 1
            result = "1+_" + keyword.upcase + "_DEF"
        elsif lines.size == 0
            result = "0_" + keyword.upcase + "_DEF"
        end

        return result
    end
end

