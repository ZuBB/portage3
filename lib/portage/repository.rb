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
            # TODO hardcoded values
            'value' => 'gentoo',
            # for public tests we need location that is
            #  * fast
            #  * available on any system
            #@'parent_dir' => '/usr',
            'parent_dir' => '/dev/shm',
            'fsvalue' => 'portage'
        }]

        repos + self.get_layman_repositories()
    end

    def self.get_layman_repositories()
        # for public tests its enough base repo
        return []
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

