#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
module InstalledPackage
    DB_PATH = '/var/db/pkg'
    ITEM_TYPES = {
        'directory' => 'dir',
        'file'      => 'obj',
        'symlink'   => 'sym'
    }
    SQL = {
        'content_type_id' => 'SELECT id FROM content_item_types where type=?;',
        'item_id' => 'select id from ipackage_content where item=?'
    }

    def self.get_data(params)
        sql_query = <<-SQL
            SELECT ip.id, c.name, p.name, e.version
            FROM installed_packages ip
            JOIN ebuilds e ON e.id = ip.ebuild_id
            JOIN packages p ON e.package_id = p.id
            JOIN categories c ON p.category_id = c.id;
        SQL

        Database.select(sql_query)
    end

    def self.get_file(param, file)
        _PF = param[2] + '-' + param[3]
        dir = File.join(InstalledPackage::DB_PATH, param[1], _PF)

        if !File.exist?(dir) || !File.directory?(dir)
            PLogger.error("Dir '#{dir}' is missed in '#{DB_PATH}'")
            return false
        end

        filepath = File.join(dir, file)

        if !File.exist?(filepath) || !File.file?(filepath)
            PLogger.info("File '#{file}' is missed in '#{filepath}'")
            return false
        end

        filepath
    end

    def self.get_symlink_id(line, cline)
        parts = line.split('->').map { |i| i.strip }
        if parts.size != 2
            PLogger.group_log([
                [3, 'Its something wrong with next item'],
                [1, cline],
            ])
            return false
        end

        item_dir = File.dirname(parts[0])
        symlink_target = File.expand_path(File.join(item_dir, parts[1]))
        symlink_id = Database.get_1value(SQL['item_id'], symlink_target)
        [parts[0], symlink_id]
    end

    def self.content_post_insert_check(item_type)
        {
            item_type =>
                Database.get_1value(SQL['content_type_id'], item_type)
        }
    end
end

