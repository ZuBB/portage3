#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 07/25/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Script
    def post_insert_check
        sql_query = <<-SQL
            SELECT c.name, p.name, e.version
            FROM categories c
            join packages p on p.category_id = c.id
            join ebuilds e on e.package_id = p.id
            join ebuilds_license_specs els on els.ebuild_id = e.id
            join license_specs ls on ls.id = els.license_spec_id
            join license_spec_content lsc on lsc.license_spec_id = ls.id
            join licenses l on l.id = lsc.license_id
            where ls.switch_type_id = 1
            group by e.id, lsc.license_id
            having count(l.id) > 1;
        SQL

        
        if (results = Database.select(sql_query)).empty?
            PLogger.info("Passed")
		else
            PLogger.error("Next ebuilds have duplicates in LICENSE variable")
			results.each { |row|
				PLogger.info("#{row[0]}/#{row[1]}-#{row[2]}")
			}
        end
    end
end

