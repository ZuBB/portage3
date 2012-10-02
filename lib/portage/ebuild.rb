#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/03/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'package'
require_relative '../common/utils'

class Ebuild < Package
    ENTITY = self.name.downcase
    PROP_SUFFIXES = [
        'text', 'version', 'description', 'homepage', 'licences', 'eapi',
        'slot', 'author', 'mtime', 'eapi_id', 'eclasses', 'parse_method',
        'iuse', 'parse_method', 'cache'
    ]
    SQL = {
        "eapi_id" => "SELECT id FROM eapis WHERE version=?",
        "id" => "SELECT id FROM ebuilds WHERE package_id=? AND version=?"
    }

    def initialize(params, strict = true)
        super(params)

        @cur_entity = ENTITY
        create_properties(PROP_SUFFIXES)
        gp_initialize(params)
        db_initialize(params)

        @ebuild_parse_method = params['method'] || 'cache'
        @curr_prop = nil
    end

    def ebuild_id
        @ebuild_id ||= Database.get_1value(SQL["id"], package_id, ebuild_version)
    end

    def ebuild_version
        @ebuild_version ||= @ebuild[@package.size + 1..-8]
    end

    def ebuild_mtime
        @mtime ||= Time.parse(
            Parser.get_value_from_cvs_header(ebuild_text, 'mtime')
        ).to_i rescue 'NAN_MTIME_DEF'
    end

    def ebuild_author
        @author ||= Parser.get_value_from_cvs_header(ebuild_text, "author")
    end

    def ebuild_description(method = nil)
        get_value('description', method)
    end

    def ebuild_keywords(method = nil)
        get_value('keywords', method)
    end

    def ebuild_homepage(method = nil)
        # http://devmanual.gentoo.org/ebuild-writing/variables/index.html
        get_value('homepage', method)
    end

    def ebuild_licences(method = nil)
        get_value('license', method)
    end

    def ebuild_slot(method = nil)
        # http://devmanual.gentoo.org/general-concepts/slotting/index.html
        get_value('slot', method)
    end

    def ebuild_use_flags(method = nil)
        # http://devmanual.gentoo.org/general-concepts/use-flags/index.html
        get_value('iuse', method)
    end

    def ebuild_eapi(method = nil)
        # http://devmanual.gentoo.org/ebuild-writing/eapi/index.html
        # Important EAPI must only be defined in ebuild files, not eclasses
        # (eclasses may have EAPI-conditional code)
        get_value('eapi')
    end

    def ebuild_eapi_id
        @ebuild_eapi_id ||= get_eapi_id
    end

    private
    def ebuild_cache
        return @ebuild_cache unless @ebuild_cache.nil?
        metadata_path = File.join(Utils.get_tree_home, 'metadata/md5-cache')
        metadata_filename = "#{package}-#{ebuild_version}"
        metadata_file = File.join(metadata_path, category, metadata_filename)
        set_prop(IO.read(metadata_file).split("\n"), 'cache')
        @ebuild_cache
    end

    def ebuild_text
        return @ebuild_text unless @ebuild_text.nil?
        set_prop(IO.read(File.join(package_home, @ebuild)).split("\n"), 'text')
        @ebuild_text
    end

    def get_prop(suffix = nil, entity = nil)
        prop_name = (entity || @cur_entity).dup

        unless prop_name.empty?
            prop_name += ('_' + suffix) if suffix.is_a?(String)
            self.instance_variable_get('@' + prop_name)
        end
    end

    def set_prop(value = nil, suffix = nil, entity = nil)
        prop_name = (entity || @cur_entity).dup

        unless prop_name.empty?
            prop_name += ('_' + suffix) if suffix.is_a?(String)
            self.instance_variable_set('@' + prop_name, value)
        end
    end

    def get_value(prop_name, method = nil)
        # get method
        method ||= @ebuild_parse_method
        # get value of the processed property
        prop_value = get_prop(prop_name)
        @curr_prop = prop_name.clone.upcase

        # if value not a nil - return it
        return prop_value unless prop_value.nil?

        # set value of the processed property
        prop_value = case method
                     when 'parse' then get_ini_value
                     when 'portageq' then get_portageq_value
                     else get_cache_value
                     end

        # set value of the processed property
        set_prop(prop_value, prop_name)
        # now we stopping its processing
        @curr_prop = nil
        # return it
        return prop_value
    end

    def get_eapi_id
        @ebuild_eapi = 0 if ebuild_eapi.end_with?('_DEF')
        Database.get_1value(SQL["eapi_id"], @ebuild_eapi)
    end

    def self.list_ebuilds(params = {})
        results = []
        sql_query = <<-SQL
            SELECT c.name, p.name, p.id
            FROM packages p
            JOIN categories c on p.category_id = c.id;
        SQL

        atoms = Database.select(sql_query)

        Database.select(Repository::SQL['all']).each do |repo_row|
            repo_home = File.join(repo_row[2], repo_row[3] || repo_row[1])
            next unless File.exist?(repo_home)

            atoms.each do |atom_row|
                package_home = File.join(repo_home, atom_row[0], atom_row[1])
                next unless File.exist?(package_home)

                Dir.glob(File.join(package_home, '*ebuild')).each do |ebuild|
                    results << {
                        'ebuild'        => ebuild[ebuild.rindex('/') + 1..-1],
                        'package'       => atom_row[1],
                        'package_id'    => atom_row[2],
                        'category'      => atom_row[0],
                        'repository'    => repo_row[1],
                        'repository_id' => repo_row[0],
                        'repository_pd' => repo_row[2],
                        'repository_fs' => repo_row[3] || repo_row[1]
                    }
                end
            end
        end

        results
    end

    def self.get_ebuilds(params = {})
        Database.select(<<-SQL
            SELECT
                r.name,
                parent_folder,
                repository_folder,
                c.name,
                p.name,
                version,
                e.id,
                e.package_id
            FROM ebuilds e
            JOIN packages p on p.id=e.package_id
            JOIN categories c on p.category_id=c.id
            JOIN repositories r on r.id=e.repository_id
			-- TODO hardcoded value
            where e.source_id = 1;
        SQL
        )
    end

    def self.generate_ebuild_params(params)
        {
            'repository'     => params[0],
            'repository_pd'  => params[1],
            'repository_fs'  => params[2],
            'category'       => params[3],
            'package'        => params[4],
            'ebuild_version' => params[5],
            'ebuild_id'      => params[6],
            'ebuild'         => params[4] + '-' + params[5] + '.ebuild'
        }
    end
end

require 'ebuild_parse'

