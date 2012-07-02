#
# Library supporting analytics scripts running on CloudDB
#
# Initial Author: Vasyl Zuzyak, 04/02/12
# Latest Modification: Vasyl Zuzyak, ...
#
require 'rubygems'
require 'nokogiri'
require 'fsobject'

module RepositoryModule
    include FSobject

    # constants
    # name of the entity
    ENTITY = self.name.downcase[0..-7]
    # sql stuff
    SQL = {
        'all' => 'SELECT * FROM repositories',
        'repository' => 'SELECT * FROM repositories WHERE id=?',
        'id@fs' => 'SELECT id FROM repositories WHERE parent_folder=? and repository_folder=?',
        'external' => 'SELECT * FROM repositories WHERE repository_name!="gentoo"',
        'any' => 'SELECT id FROM repositories limit 1'
    }

    def repository_init(params)
        # fix ff
        params = Routines.fix_params(
            params,
            ENTITY != self.class.name.downcase,
            true
        )

        # create 'system' properties for repository (sub)object
        self.create_properties(ENTITY, Routines.get_module_suffixes())

        # run inits for all kind of modules that we need to inherit
        self.gp_initialize(params)
        self.db_initialize(params)
        self.fs_initialize(params)
    end

    def repository()
        @repository ||= Database.get_1value(SQL["repository"], @repository_id)
    end

    def repository_id()
        @repository_id ||= Database.get_1value(SQL["id"], @repository)
    end

    def repository_id_by_fs()
        @repository_id ||= Database.get_1value(SQL["id@fs"], [@repository_pd, @repository_fs])
    end

    def repository_fs()
        @repository_fs ||= Database.get_1value(SQL["fs"], @repository_id)
    end

    def repository_pd()
        @repository_pd ||= Database.get_1value(SQL["pd"], @repository_id)
    end

    def home()
        File.join(@repository_pd, @repository_fs)
    end
end

