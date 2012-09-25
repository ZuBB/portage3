#
# Generic Portage object lib
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
module Equery
    W_EXACT = <<-SQL
        SELECT e.id
        FROM ebuilds e
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        WHERE c.name = ? AND p.name = ? AND e.version = ?;
    SQL

    W_CN_PN = <<-SQL
        SELECT e.id
        FROM ebuilds e
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        WHERE c.name = ? AND p.name = ?
        ORDER BY e.version_order DESC
        LIMIT 1;
    SQL

    W_PN_PV = <<-SQL
        SELECT distinct e.package_id
        FROM ebuilds e 
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        WHERE p.name = ? AND e.version = ?;
    SQL

    W_PN = <<-SQL
        SELECT distinct e.package_id
        FROM ebuilds e 
        JOIN packages p ON p.id = e.package_id
        JOIN categories c ON c.id = p.category_id
        WHERE p.name = ?;
    SQL

    W_P_ID = <<-SQL
        SELECT e.id
        FROM ebuilds e
        WHERE e.package_id = ?
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

    def self.get_ebuild_specs(atom)
        params = [atom['category'], atom['package'], atom['version']].compact

        missied_info = (
            params.empty? ||
            atom.values.all? { |i| i.nil? } || params.empty? ||
            atom['package'].nil? && atom['category'].nil? && atom['version']
        )

        if missied_info
            puts 'Please specify [CATEGORY]/PACKAGE[-VERSION]'
            exit
        end

        sql_query = W_EXACT if atom.values.none? { |i| i.nil? }
        sql_query = W_CN_PN if atom['package'] && atom['category'] && atom['version'].nil?
        sql_query = W_PN_PV if atom['package'] && atom['version'] && atom['category'].nil?
        sql_query ||= W_PN

        result = Database.select(sql_query, params)
        self.warn_ambiguous_pn(result) if result.size > 1
        result.flatten!

        if sql_query == W_PN || sql_query == W_PN_PV
            result = Database.select(W_P_ID, result)
        end

        result.flatten.first
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

