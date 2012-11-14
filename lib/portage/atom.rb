#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
class Atom
    SQL = {
        '@1' => <<-SQL
            SELECT c.name || '/' || p.name  as atom, p.id
            FROM packages p
            JOIN categories c ON p.category_id = c.id;
        SQL
    }
end

