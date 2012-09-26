#
# Generic Portage object lib
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
module Equery
    PID1 = <<-SQL
        SELECT p.id
        FROM packages p
        JOIN categories c ON c.id = p.category_id
        WHERE c.name = ? AND p.name = ?;
    SQL

    PID2 = <<-SQL
        SELECT distinct e.package_id
        FROM ebuilds e
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        WHERE p.name = ? AND e.version = ?;
    SQL

    PID3 = <<-SQL
        SELECT distinct p.id
        FROM packages p
        WHERE p.name = ?;
    SQL

    EID1 = <<-SQL
        SELECT e.id
        FROM ebuilds e
        WHERE e.package_id = ? AND e.version = ?;
    SQL

    EID2 = <<-SQL
        SELECT e.id
        FROM ebuilds e
        WHERE e.package_id = ?
            -- TODO
            ORDER BY e.version_order DESC
        LIMIT 1;
    SQL

    def self.warn_ambiguous_pn(result)
        puts 'Ambiguous package name. Choose from:'
        result.each do |row|
            puts "\t#{row[2]}/#{row[3]}"
        end

        exit
    end

    def self.get_atom_specs(input_str)
        category = nil
        package = nil
        version = nil

        if input_str.start_with?('=')
            exact_version = true
            input_str.sub!(/^=/, '')
        end

        if input_str.include?('/')
            category, package = *input_str.split('/')
        else
            package = input_str
        end

        if exact_version
            if /-r\d+$/ =~ package
                # has -rX
                verstion_start = /-[^-]+-r\d+$/ =~ package
            else
                # does not have -rX
                verstion_start = /-[^-]+$/ =~ package
            end

            version = package[verstion_start + 1..-1]
            package = package[0...verstion_start]
        end

        {
            'category' => category,
            'package' => package,
            'version' => version
        }
    end

    def self.get_package_id(atom)
        params = []

        if atom['package']
            sql_query = PID3
            params << atom['package']

            if atom['version']
                sql_query = PID2
                params << atom['version']
            elsif atom['category']
                sql_query = PID1
                params.unshift(atom['category'])
            end
        end

        unless defined?(sql_query)
            puts 'Please specify [CATEGORY/]PACKAGE[-VERSION]'
            exit
        end

        if (result = Database.select(sql_query, params)).size > 1
            self.warn_ambiguous_pn(result)
        else
            result.flatten.first
        end
    end

    def self.get_ebuild_id(atom, package_id)
        params = []

        if package_id
            sql_query = EID2
            params << package_id

            if atom['version']
                sql_query = EID1
                params << atom['version']
            end
        end

        if defined?(sql_query)
            if (result = Database.select(sql_query, params)).size > 1
                self.warn_ambiguous_pn(result)
            else
                result.flatten.first
            end
        end
    end
end

module Equery::EqueryWhich
    SQL = <<-SQL
        SELECT
            r.parent_folder,
            r.repository_folder,
            c.name,
            p.name,
            e.version
        FROM repositories r
        JOIN ebuilds e ON e.repository_id = r.id
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        WHERE e.id = ?;
    SQL

    def self.get_ebuild_path(ebuild_id)
        unless (result = Database.select(SQL, ebuild_id)).empty?
            File.join(*result) + '.ebuild'
        else
            'Can not find any package'
        end
    end
end

module Equery::EquerySize
    SQL = <<-SQL
        SELECT
            c.name,
            p.name,
            e.version,
            ip.pkgsize,
            count(ipc.id)
        FROM ebuilds e
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        JOIN installed_packages ip ON ip.ebuild_id = e.id
        JOIN ipackage_content ipc ON ipc.iebuild_id = ip.id
        WHERE e.SEARCH_FIELD = ?;
    SQL

    def self.get_package_size(package_id, ebuild_id = nil)
        params = [(ebuild_id.nil?() ? package_id : ebuild_id)]
        sql_query = SQL.clone.sub(
            'SEARCH_FIELD',
            ebuild_id.nil?() ? 'package_id' : 'id'
        )

        if (result = Database.select(sql_query, params)).size == 1
            result.flatten!
            atom = result.first(3)

            mb_size = (result[3].to_i / (1024.0 * 1024.0)).round(2)
            atom_str  = " * #{atom[0]}/#{atom[1]}-#{atom[2]}"
            files_str = "\tTotal files: #{result[4]}"
            size_str  = "\tTotal size: #{mb_size} MiB"
            "#{atom_str}\n"\
                "#{files_str}\n"\
                "#{size_str}"
        else
            'Can not determine size of the package that is not installed'
        end
    end
end

module Equery::EqueryBelongs
    SQL = <<-SQL
        SELECT
            c.name,
            p.name,
            e.version
        FROM ebuilds e
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        JOIN installed_packages ip ON ip.ebuild_id = e.id
        JOIN ipackage_content ipc ON ipc.iebuild_id = ip.id
        WHERE ipc.item = ?;
    SQL

    def self.get_iebuild_by_item(item)
		abs_path = File.expand_path(item)
		unless File.exist?(abs_path)
			return 'Passed string is not valid filepath'
		end

        unless (result = Database.select(SQL, abs_path)).empty?
			output = []
			result.each do |row|
				output << "#{row[0]}/#{row[1]}-#{row[2]} (#{abs_path})"
			end

			output.join("\n")
        else
            'Can not determine size of the package that is not installed'
        end
    end
end

module Equery::EqueryFiles
    SQL1 = <<-SQL
        SELECT
            c.name,
            p.name,
            e.version
        FROM ebuilds e
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        WHERE e.package_id = ?;
    SQL

    SQL2 = <<-SQL
        SELECT ipc.item
        FROM ebuilds e
        JOIN installed_packages ip ON ip.ebuild_id = e.id
        JOIN ipackage_content ipc ON ipc.iebuild_id = ip.id
        WHERE e.SEARCH_FIELD = ?
		ORDER BY ipc.item ASC;
    SQL

    def self.list_package_files(package_id, ebuild_id = nil)
		output = []
        atom = Database.select(SQL1, package_id).flatten
		atom_str = "#{atom[0]}/#{atom[1]}-#{atom[2]}"
		output <<  " * Contents of #{atom_str}:"

        params = [(ebuild_id.nil?() ? package_id : ebuild_id)]
        sql_query = SQL2.clone.sub(
            'SEARCH_FIELD',
            ebuild_id.nil?() ? 'package_id' : 'id'
        )

        unless (result = Database.select(sql_query, params)).empty?
			result.flatten.each { |item| output << item }
        else
			output << "No installed packages matching '#{atom_str}'"
        end

		output.join("\n")
    end
end

