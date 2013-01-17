#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Atom
    # atom prefix matcher
    VERSION_RESTRICTION = Regexp.new("^[^\\w]+")
    # regexp to match version
    ATOM_VERSION = Regexp.new('((?:-)(\\d[^:]*))?(?:(?::)(\\d.*))?$')

    SQL = {
        '@1' => <<-SQL
            SELECT c.name || '/' || p.name as atom, p.id
            FROM packages p
            JOIN categories c ON p.category_id = c.id;
        SQL
    }
    SQL['@2'] = <<-SQL
        SELECT c.name || '/' || p.name || '-' || e.version as CPF, e.id
        FROM packages p
        JOIN categories c ON p.category_id = c.id
        JOIN ebuilds e ON p.id = e.package_id;
    SQL

    def self.get_package(pf)
        package = nil

        if /-r\d+$/ =~ pf
            # has -rX
            verstion_start = /-[^-]+-r\d+$/ =~ pf
        elsif /-\d[^-]*$/ =~ pf
            # does not have -rX
            verstion_start = /-\d[^-]*$/ =~ pf
        end

        package = pf[0...verstion_start] unless verstion_start.nil?
        package
    end

    def self.get_version(pf)
        version = nil

        if /-r\d+$/ =~ pf
            # has -rX
            verstion_start = /-[^-]+-r\d+$/ =~ pf
        elsif /-\d[^-]*$/ =~ pf
            # does not have -rX
            verstion_start = /-\d[^-]*$/ =~ pf
        end

        version = pf[verstion_start + 1..-1] unless verstion_start.nil?
        version
    end

    def self.get_ebuilds(params)
        sql_query = 'SELECT id FROM ebuilds WHERE package_id = ?'
        sql_query_params = [params["package_id"]]

        # take care about slot
        unless params["slot"].nil?
            sql_query << ' and slot = ?'
            sql_query_params << params["slot"]
        end

        # NOTE start of section that needs cleanup
        # take care about version that ends with '*'
        if !params["version"].nil? && params["version"].end_with?('*') && params["vrestr"] == '='
            sql_query_params << (params["version"].sub('*', '') + '%')
            sql_query << ' AND version like ?'
        # take care about direct version
        elsif params["vrestr"] == '='
            sql_query_params << params["version"]
            sql_query << ' AND version = ?'
        end

        # take care about custom version restrictions
        if !params["version"].nil? && !params["vrestr"].nil? && params["vrestr"] != '='
            sql_query_params << params["package_id"] << (params["version"] + '%')
            sql_query << <<-SQL
                AND version_order #{params["vrestr"]} (
                    SELECT version_order
                    FROM ebuilds
                    WHERE
                        package_id = ? AND
                        version like ?
                    ORDER by version_order ASC
                    LIMIT 1
                )
            SQL
        end
        # NOTE end of section that needs cleanup

        db_client = Portage3::Database.get_client
        db_client.select(sql_query, sql_query_params).flatten
    end
end

