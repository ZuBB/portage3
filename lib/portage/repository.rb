#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'nokogiri'
require 'fsobject'

class Repository
    include FSobject

    ENTITY = self.name.downcase
    SQL = {
        'all' => 'SELECT * FROM repositories;',
        'repository' => 'SELECT * FROM repositories WHERE id=?',
        'id@fs' => 'SELECT id FROM repositories WHERE parent_folder=? and repository_folder=?',
        'external' => 'SELECT * FROM repositories WHERE repository_name!="gentoo"',
        'any' => 'SELECT id FROM repositories limit 1'
    }

    def initialize(params)
        @cur_entity = ENTITY
        gp_initialize(params)
        db_initialize(params)
        fs_initialize(params)
    end

    def repository()
        @repository ||= Database.get_1value(SQL["repository"], @repository_id)
    end

    def repository_id()
        @repository_id ||= Database.get_1value(SQL["id"], @repository)
    end

    def repository_id_by_fs()
        @repository_id ||= Database.get_1value(SQL["id@fs"], @repository_pd, @repository_fs)
    end

    def repository_fs()
        @repository_fs ||= Database.get_1value(SQL["fs"], @repository_id)
    end

    def repository_pd()
        @repository_pd ||= Database.get_1value(SQL["pd"], @repository_id)
    end

    def repository_home()
        File.join(@repository_pd, @repository_fs)
    end

    def self.get_repositories(params = {})
        repos = [{
            'repository_pd' => File.dirname(params['tree_home']),
            'repository_fs' => File.basename(params['tree_home']),
            'repository' => IO.read(File.join(params['profiles2_home'],
                                              'repo_name'
                                             )
                                   ).strip
        }]

        if Utils::SETTINGS['overlay_support']
            repos =+ self.get_layman_repositories()
        end

        repos
    end

    def self.get_layman_repositories()
        repos = []
        layman_config = '/etc/layman/layman.cfg'
        return repos unless File.exist?(layman_config)

        layman_storage = %x[grep ^storage #{layman_config}]
        layman_storage = layman_storage.split(':')[1].strip()

        layman_local_list = %x[grep ^local_list #{layman_config}]
        layman_local_list = layman_local_list.split(':')[1].strip()
        layman_local_list.sub!(/%\(storage\)s\//, '')
        layman_local_list = File.join(layman_storage, layman_local_list)

        xml_doc = Nokogiri::XML(IO.read(layman_local_list))
        xml_doc.xpath('//repo/name').each do |name_node|
            repos << {
                'repository' => name_node.inner_text.strip(),
                'repository_fs' => name_node.inner_text.strip(),
                'repository_pd' => layman_storage
            }
        end

        repos
    end
end

