create table system_settings (
    id INTEGER,
    param VARCHAR NOT NULL UNIQUE,
    value INTEGER NOT NULL,
    PRIMARY KEY (id)
);

create table completed_tasks (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table architectures (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table platforms (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table arches (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    architecture_id INTEGER NOT NULL,
    platform_id INTEGER NOT NULL,
    FOREIGN KEY (architecture_id) REFERENCES architectures(id),
    FOREIGN KEY (platform_id) REFERENCES platforms(id),
    CONSTRAINT idx1_unq UNIQUE (name, architecture_id, platform_id),
    PRIMARY KEY (id)
);

create table keywords (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    -- symbol VARCHAR NOT NULL UNIQUE, /*really not null?*/
    PRIMARY KEY (id)
);

create table profiles (
    -- profile is any dir from 'base' basedir that has 'eapi' file inside
    id INTEGER,
    name VARCHAR NOT NULL,
    arch_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (status_id) REFERENCES profile_statuses(id),
    CONSTRAINT idx1_unq UNIQUE (name, arch_id, status_id),
    PRIMARY KEY (id)
);

create table profile_statuses (
    id INTEGER,
    status VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table sources (
    id INTEGER,
    source VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table eapis (
    id INTEGER,
    version INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table mask_states (
    id INTEGER,
    state VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table content_item_types (
    id INTEGER,
    type VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table switch_types (
    id INTEGER,
    type VARCHAR NOT NULL UNIQUE,
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
    status VARCHAR NOT NULL,
    PRIMARY KEY (id)
);

create table flags (
    id INTEGER,
    type_id INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    descr VARCHAR,
    package_id INTEGER,
    -- what happens if flags are defined in overlay
    source_id INTEGER NOT NULL,
    -- do we need this?
    repository_id INTEGER,
    FOREIGN KEY (type_id) REFERENCES flag_types(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    FOREIGN KEY (repository_id) REFERENCES repositories(id),
    PRIMARY KEY (id)
);

CREATE INDEX flag_name_idx1 on flags(name);

create table licenses (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    repository_id INTEGER NOT NULL,
    FOREIGN KEY (repository_id) REFERENCES repositories(id),
    PRIMARY KEY (id)
);

create table license_groups (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    repository_id INTEGER NOT NULL,
    FOREIGN KEY (repository_id) REFERENCES repositories(id),
    PRIMARY KEY (id)
);

create table license_group_content (
    id INTEGER,
    group_id INTEGER NOT NULL,
    sub_group_id INTEGER,
    license_id INTEGER,
    FOREIGN KEY (group_id) REFERENCES license_groups(id),
    FOREIGN KEY (sub_group_id) REFERENCES license_groups(id),
    FOREIGN KEY (license_id) REFERENCES licenses(id),
    CONSTRAINT idx1_unq UNIQUE (group_id, license_id),
    CONSTRAINT idx2_unq UNIQUE (group_id, sub_group_id),
    CONSTRAINT chk1 CHECK
        (license_id IS NOT NULL OR sub_group_id IS NOT NULL),
    CONSTRAINT chk2 CHECK (group_id != sub_group_id),
    PRIMARY KEY (id)
);

create table repositories (
    -- TODO find best way to handle repos
    --   that used to be in use but are removed now
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    parent_folder VARCHAR NOT NULL,
    repository_folder VARCHAR,
    PRIMARY KEY (id)
);

create table categories (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    source_id INTEGER NOT NULL,
    descr VARCHAR,
    FOREIGN KEY (source_id) REFERENCES sources(id),
    PRIMARY KEY (id)
);

create table packages (
    id INTEGER,
    name VARCHAR NOT NULL,
    category_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    CONSTRAINT idx1_unq UNIQUE (category_id, name),
    PRIMARY KEY (id)
);

CREATE INDEX packages_idx0 on packages(name);

create table ebuilds (
    id INTEGER,
    package_id INTEGER NOT NULL,
    version VARCHAR NOT NULL,
    version_order INTEGER NOT NULL DEFAULT 0,
    repository_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    mtime INTEGER,
    mauthor VARCHAR,
    raw_eapi VARCHAR,
    eapi_id INTEGER,
    slot VARCHAR,
    description_id INTEGER,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (eapi_id) REFERENCES eapis(id),
    FOREIGN KEY (repository_id) REFERENCES repositories(id),
    FOREIGN KEY (description_id) REFERENCES ebuild_descriptions (id),
    CONSTRAINT idx1_unq UNIQUE (package_id, version, repository_id),
    PRIMARY KEY (id)
);

CREATE INDEX ebuilds_idx2 on ebuilds (package_id, version);
CREATE INDEX ebuilds_idx3 on ebuilds (package_id);

create table ebuild_descriptions (
    id INTEGER,
    descr VARCHAR NOT NULL UNIQUE,
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

create table ebuilds_keywords (
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

create table ebuilds_masks (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    arch_id INTEGER,
    profile_id INTEGER,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (state_id) REFERENCES mask_states(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    CONSTRAINT chk1 CHECK (arch_id IS NOT NULL OR profile_id IS NOT NULL),
    -- TODO replace this constraint with trigger(s)
    --CONSTRAINT idx1_unq UNIQUE (ebuild_id, arch_id, state_id, source_id),
    PRIMARY KEY (id)
);

-- TODO add check(s)
create table flags_states (
    id INTEGER,
    profile_id INTEGER,
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
    PRIMARY KEY (id)
);

CREATE INDEX flags_states_idx3 on flags_states(package_id, ebuild_id);

create table ebuilds_license_specs (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    license_spec_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (license_spec_id) REFERENCES licenses_specs(id),
    CONSTRAINT idx1_unq UNIQUE (ebuild_id, license_spec_id),
    PRIMARY KEY (id)
);

create table license_specs (
    id INTEGER,
    switch_type_id INTEGER NOT NULL,
    spec_dep_id INTEGER,
    FOREIGN KEY (switch_type_id) REFERENCES switch_types(id),
    PRIMARY KEY (id)
);

create table license_spec_switches (
    id INTEGER,
    license_spec_id INTEGER NOT NULL,
    flag_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    FOREIGN KEY (license_spec_id) REFERENCES licenses_specs(id),
    FOREIGN KEY (flag_id) REFERENCES flags(id),
    FOREIGN KEY (state_id) REFERENCES flag_states(id),
    CONSTRAINT idx1_unq UNIQUE (license_spec_id, flag_id, state_id),
    -- check if its possible to use some check for this
    PRIMARY KEY (id)
);

create table license_spec_content (
    id INTEGER,
    license_spec_id INTEGER NOT NULL,
    license_id INTEGER NOT NULL,
    FOREIGN KEY (license_spec_id) REFERENCES licenses_specs(id),
    FOREIGN KEY (license_id) REFERENCES licenses(id),
    CONSTRAINT idx1_unq UNIQUE (license_spec_id, license_id),
    -- check if its possible to use some check for this
    PRIMARY KEY (id)
);

create table sets (
    id INTEGER,
    name VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table set_content (
    id INTEGER,
    set_id INTEGER NOT NULL,
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
    ebuild_id INTEGER NOT NULL UNIQUE,
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

create table ipackage_content (
    id INTEGER,
    iebuild_id INTEGER NOT NULL,
    type_id INTEGER NOT NULL,
    item VARCHAR NOT NULL,
    -- can't use UNIQUE as we have same objects in FS
    --  under different names and/or packages
    hash VARCHAR,
    install_time INTEGER,
    -- check if its possible to use some check for this
    symlinkto INTEGER,
    FOREIGN KEY (iebuild_id) REFERENCES installed_packages(id),
    FOREIGN KEY (type_id) REFERENCES content_item_types(id),
    CONSTRAINT idx1_unq UNIQUE (iebuild_id, type_id, item),
    -- need to enforce somehow next cases
    --  * hash and install_time can not be NULL in case of type is 'file'
    --  * install_time can not be NULL in case of type is 'symlink'
    PRIMARY KEY (id)
);

CREATE INDEX package_content_idx3 on ipackage_content(item);

create table ipackage_flagstates (
    id INTEGER,
    iebuild_id INTEGER NOT NULL,
    flag_id INTEGER NOT NULL,
    state_id INTEGER NOT NULL,
    FOREIGN KEY (flag_id) REFERENCES flags(id),
    FOREIGN KEY (state_id) REFERENCES flag_states(id),
    CONSTRAINT idx1_unq UNIQUE (iebuild_id, flag_id, state_id),
    PRIMARY KEY (id)
);

-- TEMPORARY TABLES --

CREATE TABLE tmp_ebuild_descriptions (
    id INTEGER,
    descr VARCHAR NOT NULL,
    ebuild_id INTEGER NOT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX ted on tmp_ebuild_descriptions (descr);


CREATE TABLE IF NOT EXISTS tmp_ebuild_homepages (
    id INTEGER,
    homepage VARCHAR NOT NULL,
    ebuild_id INTEGER NOT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX teh on tmp_ebuild_homepages (homepage);


CREATE TABLE IF NOT EXISTS tmp_profile_mask_categories (
    id INTEGER,
    category VARCHAR NOT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX tpmc on tmp_profile_mask_categories(category);


CREATE TABLE IF NOT EXISTS tmp_profile_mask_packages (
    id INTEGER,
    package VARCHAR NOT NULL,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id),
    PRIMARY KEY (id)
);

CREATE INDEX tpmp on tmp_profile_mask_packages(package);


CREATE TABLE IF NOT EXISTS tmp_profile_mask_ebuilds (
    version VARCHAR NOT NULL,
    package_id INTEGER NOT NULL,
    FOREIGN KEY (package_id) REFERENCES package(id)
);

CREATE INDEX tpme1 on tmp_profile_mask_ebuilds(version);
CREATE INDEX tpme2 on tmp_profile_mask_ebuilds(version, package_id);


CREATE TABLE IF NOT EXISTS tmp_etc_portage_mask_ebuilds (
    version VARCHAR NOT NULL,
    package_id INTEGER NOT NULL,
    FOREIGN KEY (package_id) REFERENCES package(id)
);

CREATE INDEX tepme1 on tmp_etc_portage_mask_ebuilds(version);
CREATE INDEX tepme2 on tmp_etc_portage_mask_ebuilds(version, package_id);

