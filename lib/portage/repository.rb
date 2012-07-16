#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'repository_module'

class Repository
    include RepositoryModule

    def initialize(params)
        # run init
        self.repository_init(params)
    end

    def self.get_repositories(params = {})
        repos = [{
            'parent_dir' => File.dirname(params['tree_home']),
            'fsvalue' => File.basename(params['tree_home']),
            'value' => IO.read(File.join(
                params['profiles2_home'], 'repo_name'
            )).strip
        }]

        if Utils::Settings['overlay_support']
            repos =+ self.get_layman_repositories()
        end

        repos
    end

    def self.get_layman_repositories()
        # for public tests its enough base repo
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
                'value' => name_node.inner_text.strip(),
                'parent_dir' => layman_storage
            }
        end

        return repos
    end
end

