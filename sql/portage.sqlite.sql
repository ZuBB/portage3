BEGIN TRANSACTION;

create table system_settings (
    id INTEGER,
    param VARCHAR NOT NULL UNIQUE,
    value INTEGER NOT NULL,
    PRIMARY KEY (id)
);

create table architectures (
    id INTEGER,
    architecture VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table platforms (
    id INTEGER,
    platform_name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table arches (
    id INTEGER,
    arch_name VARCHAR NOT NULL UNIQUE,
    architecture_id INTEGER NOT NULL,
    platform_id INTEGER NOT NULL,
    FOREIGN KEY (architecture_id) REFERENCES architectures(id),
    FOREIGN KEY (platform_id) REFERENCES platforms(id),
    CONSTRAINT idx1_unq UNIQUE (arch_name, architecture_id, platform_id),
    PRIMARY KEY (id)
);

create table keywords (
    id INTEGER,
    keyword VARCHAR NOT NULL UNIQUE,
    -- symbol VARCHAR NOT NULL UNIQUE, /*really not null?*/
    PRIMARY KEY (id)
);

create table profiles (
    -- profile is any dir from 'base' basedir that has 'eapi' file inside
    id INTEGER,
    profile_name VARCHAR NOT NULL,
    arch_id INTEGER NOT NULL,
    profile_status_id INTEGER NOT NULL,
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (profile_status_id) REFERENCES profile_statuses(id),
    CONSTRAINT idx1_unq UNIQUE (profile_name, arch_id, profile_status_id),
    PRIMARY KEY (id)
);

create table profile_statuses (
    id INTEGER,
    profile_status VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table sources (
    id INTEGER,
    source VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table eapis (
    id INTEGER,
    eapi_version INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table mask_states (
    id INTEGER,
    mask_state VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table content_item_types (
    id INTEGER,
    type VARCHAR NOT NULL,
    PRIMARY KEY (id)
);

create table flag_types (
    id INTEGER,
    type VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table flag_states (
    id INTEGER,
    state VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table flags (
    id INTEGER,
    name VARCHAR NOT NULL,
    descr VARCHAR DEFAULT NULL,
    type_id INTEGER NOT NULL,
    live INTEGER NOT NULL DEFAULT 1,
    package_id INTEGER DEFAULT NULL,
    FOREIGN KEY (type_id) REFERENCES flag_types(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    PRIMARY KEY (id)
);

create table licences (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table licence_groups (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table licence_group_content (
    id INTEGER,
    group_id INTEGER NOT NULL,
    sub_group_id INTEGER,
    licence_id INTEGER,
    FOREIGN KEY (group_id) REFERENCES licence_groups(id),
    FOREIGN KEY (sub_group_id) REFERENCES licence_groups(id),
    FOREIGN KEY (licence_id) REFERENCES licences(id),
    CONSTRAINT idx1_unq UNIQUE (group_id, licence_id),
    CONSTRAINT idx1_unq UNIQUE (group_id, sub_group_id),
    CONSTRAINT idx2_unq CHECK
        (licence_id IS NOT NULL OR sub_group_id IS NOT NULL),
    PRIMARY KEY (id)
);

create table repositories (
    id INTEGER,
    repository_name VARCHAR NOT NULL UNIQUE,
    parent_folder VARCHAR NOT NULL,
    repository_folder VARCHAR,
    PRIMARY KEY (id)
);

create table categories (
    id INTEGER,
    category_name VARCHAR NOT NULL UNIQUE,
    description VARCHAR NOT NULL,
    PRIMARY KEY (id)
);

create table packages (
    id INTEGER,
    category_id INTEGER NOT NULL,
    package_name VARCHAR NOT NULL,
    CONSTRAINT idx1_unq UNIQUE (category_id, package_name),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    PRIMARY KEY (id)
);

create table ebuilds (
    id INTEGER,
    package_id INTEGER NOT NULL,
    version VARCHAR NOT NULL,
    version_order INTEGER NOT NULL DEFAULT 0,
    mtime INTEGER /*NOT NULL*/,
    mauthor VARCHAR /*NOT NULL*/,
    eapi_id INTEGER /*NOT NULL*/,
    slot VARCHAR /*NOT NULL*/,
    repository_id INTEGER NOT NULL,
    description_id INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (eapi_id) REFERENCES eapis(id),
    FOREIGN KEY (repository_id) REFERENCES repositories (id),
    FOREIGN KEY (description_id) REFERENCES ebuild_descriptions (id),
    CONSTRAINT idx1_unq UNIQUE (package_id, version, repository_id),
    PRIMARY KEY (id)
);

CREATE INDEX ebuilds_idx2 on ebuilds (package_id, version);
CREATE INDEX ebuilds_idx3 on ebuilds (package_id);

create table ebuild_descriptions (
    id INTEGER,
    description VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table ebuild_homepages (
    id INTEGER,
    homepage VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table ebuilds_homepages (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    homepage_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (homepage_id) REFERENCES ebuild_homepages(id),
    PRIMARY KEY (id)
);

create table ebuild_keywords (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    arch_id INTEGER NOT NULL,
    keyword_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (keyword_id) REFERENCES keywords(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    CONSTRAINT idx1_unq UNIQUE (
        ebuild_id, arch_id, keyword_id, source_id
    ),
    PRIMARY KEY (id)
);

create table ebuild_masks (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    arch_id INTEGER NOT NULL,
    mask_state_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (mask_state_id) REFERENCES mask_states(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    CONSTRAINT idx1_unq UNIQUE (
        ebuild_id, arch_id, mask_state_id, source_id
    ),
    PRIMARY KEY (id)
);

create table flags_states (
    id INTEGER,
    package_id INTEGER,
    ebuild_id INTEGER,
    flag_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (flag_id) REFERENCES flags(id),
    FOREIGN KEY (state_id) REFERENCES flag_states(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    CONSTRAINT idx1_unq UNIQUE (flag_id, state_id, ebuild_id),
    PRIMARY KEY (id)
);

create table ebuild_licences (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    licence_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (licence_id) REFERENCES licences(id),
    CONSTRAINT idx1_unq UNIQUE (licence_id, ebuild_id),
    PRIMARY KEY (id)
);

create table sets (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table set_content (
    id INTEGER,
    set_id INTEGER NOT NULL UNIQUE,
    sub_set_id INTEGER,
    package_id INTEGER,
    FOREIGN KEY (set_id) REFERENCES sets(id),
    FOREIGN KEY (sub_set_id) REFERENCES sets(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    CONSTRAINT idx1_unq CHECK
        (sub_set_id IS NOT NULL OR package_id IS NOT NULL),
    -- TODO slot?
    PRIMARY KEY (id)
);

create table installed_packages (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    build_time INTEGER NOT NULL,
    binpkgmd5 VARCHAR,
    pkgsize INTEGER NOT NULL,
    cflags VARCHAR /*NOT NULL*/,
    cxxflags VARCHAR /*NOT NULL*/,
    ldflags VARCHAR /*NOT NULL*/,
    counter INTEGER /*NOT NULL*/,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    PRIMARY KEY (id)
);

create table package_content (
    id INTEGER,
    iebuild_id INTEGER NOT NULL,
    type_id INTEGER NOT NULL,
    item VARCHAR NOT NULL,
    -- can't use UNIQUE as we have same objects in FS
    --  under different names and/or packages
    hash VARCHAR DEFAULT NULL,
    install_time INTEGER DEFAULT NULL,
    -- check if its possible to use some check for this
    symlinkto INTEGER DEFAULT NULL,
    FOREIGN KEY (iebuild_id) REFERENCES installed_packages(id),
    FOREIGN KEY (type_id) REFERENCES content_item_types(id),
    CONSTRAINT idx1_unq UNIQUE (iebuild_id, type_id, item),
    -- any other check/constraint here?
    PRIMARY KEY (id)
);

CREATE INDEX package_content_idx3 on package_content(item);

create table package_flagstates (
    id INTEGER,
    iebuild_id INTEGER NOT NULL,
    flag_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    FOREIGN KEY (flag_id) REFERENCES flags(id),
    FOREIGN KEY (state_id) REFERENCES flag_states(id),
    CONSTRAINT idx1_unq UNIQUE (iebuild_id, flag_id, state_id),
    PRIMARY KEY (id)
);

COMMIT;

