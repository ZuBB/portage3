#!/usr/bin/env ruby
# encoding: UTF-8
#
# Here should go some comment
#
# Initial Author: Vasyl Zuzyak, 01/04/12
# Latest Modification: Vasyl Zuzyak, 01/06/12
#
def run_check(sql_query, message)
    if (results = Database.select(sql_query)).size > 0
        PLogger.error(message)
        affected_by_max.each { |row| PLogger.info(row[0] + '/' + row[1]) }
    end
end

class Script
    def post_insert_check
        [
            {
                'message' => 'Next packages have zeros in `version_order` column',
                'sql_query' => <<-SQL
                    select c.category_name, p.package_name
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
                    select c.category_name, p.package_name
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
                    select c.category_name, p.package_name
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
        ].each { |item| run_check(item['message'], item['sql_query']) }
    end
end

