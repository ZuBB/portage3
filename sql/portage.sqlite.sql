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

/*create table restriction_types (
    id INTEGER,
    restriction VARCHAR NOT NULL UNIQUE,
    -- sql_query VARCHAR NOT NULL UNIQUE,
    -- CONSTRAINT idx1_unq UNIQUE (restriction, sql_query),
    PRIMARY KEY (id)
);*/

create table mask_states (
    id INTEGER,
    mask_state VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table use_flags_states (
    id INTEGER,
    flag_state VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table use_flags_types (
    id INTEGER,
    flag_type VARCHAR NOT NULL UNIQUE,
    description VARCHAR NOT NULL UNIQUE,
    source VARCHAR NOT NULL,
    PRIMARY KEY (id)
);

create table use_flags (
    id INTEGER,
    flag_name VARCHAR NOT NULL,
    flag_description VARCHAR NOT NULL,
    flag_type_id INTEGER NOT NULL,
    package_id INTEGER,
    FOREIGN KEY (flag_type_id) REFERENCES use_flags_types(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    PRIMARY KEY (id)
);

/* create table persons (
    id INTEGER,
    name VARCHAR,
    email VARCHAR NOT NULL UNIQUE,
    nickname VARCHAR UNIQUE,
    CONSTRAINT idx1_unq UNIQUE (name, email, nickname),
    PRIMARY KEY (id)
);

create table roles (
    id INTEGER,
    role VARCHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table persons2roles (
    id INTEGER,
    person_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    FOREIGN KEY (person_id) REFERENCES persons(id),
    FOREIGN KEY (role_id) REFERENCES roles(id),
    CONSTRAINT idx1_unq UNIQUE (person_id, role_id),
    PRIMARY KEY (id)
);

create table person_roles2packages (
    id INTEGER,
    package_id INTEGER NOT NULL,
    persons_role_id INTEGER NOT NULL,
    FOREIGN KEY (persons_role_id) REFERENCES persons2roles(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    CONSTRAINT idx1_unq UNIQUE (package_id, persons_role_id),
    PRIMARY KEY (id)
);*/

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
    homepage_id INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (eapi_id) REFERENCES eapis(id),
    FOREIGN KEY (repository_id) REFERENCES repositories (id),
    FOREIGN KEY (description_id) REFERENCES ebuild_descriptions (id),
    FOREIGN KEY (homepage_id) REFERENCES ebuild_homepages (id),
    CONSTRAINT idx1_unq UNIQUE (package_id, version, repository_id),
    PRIMARY KEY (id)
    -- inherit/manifest
    -- data blob /*NOT NULL*/,
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

create table use_flags2ebuilds (
    id INTEGER,
    -- do we need package_id here
    package_id INTEGER NOT NULL,
    ebuild_id INTEGER NOT NULL,
    use_flag_id INTEGER NOT NULL,
    flag_state INTEGER NOT NULL DEFAULT 0,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (use_flag_id) REFERENCES use_flags(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    CONSTRAINT idx1_unq UNIQUE (ebuild_id, use_flag_id, flag_state),
    PRIMARY KEY (id)
);

/*create table package_licenses (
    id INTEGER,
    license VARCHAR NOT NULL UNIQUE,
    -- url/hdd location ?
    PRIMARY KEY (id)
);

create table licenses2ebuilds (
    id INTEGER,
    license_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL,
    ebuild_id INTEGER NOT NULL,
    CONSTRAINT idx1_unq UNIQUE (license_id, package_id, ebuild_id),
    FOREIGN KEY (license_id) REFERENCES package_licenses(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    PRIMARY KEY (id)
);*/

/*create table sets (
    id INTEGER PRIMARY KEY,
    set_name VARCHAR NOT NULL
);

create table sets_content (
    id INTEGER PRIMARY KEY,
    set_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL
);*/

create table installed_apps (
    id INTEGER,
    package_id INTEGER NOT NULL,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    PRIMARY KEY (id)
);

COMMIT;
