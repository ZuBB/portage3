#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 01/05/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'pathname'

module InstalledPackage
    DB_PATH = '/var/db/pkg'
    ITEM_TYPES = {
        'directory' => 'dir',
        'file'      => 'obj',
        'symlink'   => 'sym'
    }
    SQL = {
        '@1' => 'SELECT type, id FROM content_item_types;',
        '@2' => <<-SQL
            SELECT item, id
            FROM ipackage_content
            WHERE type_id = (
                SELECT id
                FROM content_item_types
                WHERE type = '#{ITEM_TYPES['file']}'
            );
        SQL
    }
    SQL['@3'] = <<-SQL
        SELECT item, id
        FROM ipackage_content
        WHERE type_id = (
            SELECT id
            FROM content_item_types
            WHERE type = '#{ITEM_TYPES['symlink']}'
        );
    SQL

    def self.get_data(params)
        sql_query = <<-SQL
            SELECT ip.id, c.name, p.name, e.version
            FROM installed_packages ip
            JOIN ebuilds e ON e.id = ip.ebuild_id
            JOIN packages p ON e.package_id = p.id
            JOIN categories c ON p.category_id = c.id;
        SQL

        Portage3::Database.get_client.select(sql_query)
    end

    def self.get_file(param, file, silent = false)
        _PF = param[2] + '-' + param[3]
        dir = File.join(InstalledPackage::DB_PATH, param[1], _PF)

        if !File.exist?(dir) || !File.directory?(dir)
            PLogger.error("Dir '#{dir}' is missed in '#{DB_PATH}'") unless silent
            return false
        end

        filepath = File.join(dir, file)

        if !File.exist?(filepath) || !File.file?(filepath)
            PLogger.info("File '#{file}' is missed in '#{filepath}'") unless silent
            return false
        end

        filepath
    end

    def self.get_filepath(path_part, filename, silent = false)
        filepath = File.join(path_part, filename)

        if !File.exist?(filepath) || !File.file?(filepath)
            PLogger.warn("File '#{file}' is missed") unless silent
            return false
        end

        filepath
    end

    def self.get_file_content(path_part, filename)
        method_name = path_part.is_a?(Array) ? 'get_file' : 'get_filepath'
        filepath = self.send(method_name, path_part, filename, true)
        content = nil

        if filepath.is_a?(String) && File.readable?(filepath)
            content = IO.read(filepath).strip

            if !content.is_a?(String) || content.empty?
                # TODO PLogger.warn("File '#{filepath}' has invalid content")
                return content
            end
        end

        content
    end

    def self.get_file_lines(path_part, filename)
        content = self.get_file_content(path_part, filename)
        content.is_a?(String) ? content.lines : []
    end

    def self.symlink_target(parts)
        if Pathname.new(parts[1]).absolute?
            parts[1]
        else
            path = File.join(File.dirname(parts[0]), parts[1])
            path = File.expand_path(path) if parts[1].start_with?('.')
            path
        end
    end
end

