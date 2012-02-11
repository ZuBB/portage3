BEGIN TRANSACTION;

create table system_settings (
    id INTEGER,
    option CHAR NOT NULL UNIQUE,
    value INTEGER NOT NULL,
    PRIMARY KEY (id)
);

create table architectures (
    id INTEGER,
    architecture CHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
    -- smth else?
);

create table platforms (
    id INTEGER,
    platform_name CHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table arches (
    -- here will be all items from profiles/arch.list file
    id INTEGER,
    arch_name CHAR NOT NULL UNIQUE,
    architecture_id INTEGER NOT NULL,
    platform_id INTEGER NOT NULL,
    FOREIGN KEY (architecture_id) REFERENCES architectures(id),
    FOREIGN KEY (platform_id) REFERENCES platforms(id),
    CONSTRAINT idx1_unq UNIQUE (arch_name, architecture_id, platform_id),
    PRIMARY KEY (id)
);

create table keywords (
    id INTEGER,
    keyword CHAR NOT NULL UNIQUE,
    -- symbol CHAR NOT NULL UNIQUE, /*really not null?*/
    PRIMARY KEY (id)
);

create table profiles (
    -- profile is any dir from 'base' basedir that has 'eapi' file inside
    id INTEGER,
    profile_name CHAR NOT NULL,
    arch_id INTEGER NOT NULL,
    profile_status_id INTEGER NOT NULL,
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (profile_status_id) REFERENCES profile_statuses(id),
    CONSTRAINT idx1_unq UNIQUE (profile_name, arch_id, profile_status_id),
    PRIMARY KEY (id)
);

create table profile_statuses (
    id INTEGER,
    profile_status CHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table sources (
    id INTEGER,
    source CHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table eapis (
    id INTEGER,
    eapi_version INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table restriction_types (
    id INTEGER,
    restriction CHAR NOT NULL UNIQUE,
    -- sql_query CHAR NOT NULL UNIQUE,
    -- CONSTRAINT idx1_unq UNIQUE (restriction, sql_query),
    PRIMARY KEY (id)
);

create table mask_states (
    id INTEGER,
    mask_state CHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table categories (
    id INTEGER,
    category_name CHAR NOT NULL UNIQUE,
    description CHAR NOT NULL,
    PRIMARY KEY (id)
);

create table packages (
    id INTEGER,
    category_id INTEGER NOT NULL,
    package_name CHAR NOT NULL,
    description CHAR NOT NULL,
    homepage CHAR NOT NULL,
    CONSTRAINT idx1_unq UNIQUE (category_id, package_name),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    PRIMARY KEY (id)
);

/* create table use_flags (
    id INTEGER,
    flag_name CHAR NOT NULL UNIQUE,
    flag_description CHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table use_flags_states (
    id INTEGER,
    flag_state CHAR NOT NULL UNIQUE,
    PRIMARY KEY (id)
);

create table profile_use_flags (
    id INTEGER,
    use_flag_id INTEGER NOT NULL,
    flag_state_id INTEGER NOT NULL DEFAULT 1,
    -- todo profile_id
    FOREIGN KEY (use_flag_id) REFERENCES all_use_flags(id),
    FOREIGN KEY (flag_state_id) REFERENCES use_flags_states(id),
    CONSTRAINT idx1_unq UNIQUE (use_flag_id, flag_state_id),
    PRIMARY KEY (id)
);

create table system_use_flags (
    id INTEGER,
    use_flag_id INTEGER NOT NULL,
    flag_state_id INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (use_flag_id) REFERENCES all_use_flags(id),
    FOREIGN KEY (flag_state_id) REFERENCES use_flags_states(id),
    CONSTRAINT idx1_unq UNIQUE (use_flag_id, flag_state_id),
    PRIMARY KEY (id)
);

create table users_use_flags2packages (
    id INTEGER,
    use_flag_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL,
    flag_state_id INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (use_flag_id) REFERENCES all_use_flags(id),
    FOREIGN KEY (flag_state_id) REFERENCES use_flags_states(id),
    CONSTRAINT idx1_unq UNIQUE (use_flag_id, flag_state_id, package_id),
    PRIMARY KEY (id)
);

create table users_use_flags2ebuilds (
    id INTEGER,
    use_flag_id INTEGER NOT NULL,
    ebuild_id INTEGER NOT NULL,
    flag_state_id INTEGER NOT NULL DEFAULT 1,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (use_flag_id) REFERENCES all_use_flags(id),
    FOREIGN KEY (flag_state_id) REFERENCES use_flags_states(id),
    CONSTRAINT idx1_unq UNIQUE (use_flag_id, flag_state_id, ebuild_id),
    PRIMARY KEY (id)
);

create table persons (
    id INTEGER,
    name CHAR,
    email CHAR NOT NULL UNIQUE,
    nickname CHAR UNIQUE,
    CONSTRAINT idx1_unq UNIQUE (name, email, nickname),
    PRIMARY KEY (id)
);

create table roles (
    id INTEGER,
    role CHAR NOT NULL UNIQUE,
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

create table ebuilds (
    id INTEGER,
    package_id INTEGER NOT NULL,
    version CHAR NOT NULL,
    license CHAR NOT NULL,
    mtime CHAR NOT NULL,
    mauthor CHAR NOT NULL,
    eapi_id INTEGER NOT NULL,
    slot CHAR NOT NULL,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (eapi_id) REFERENCES eapis(id),
    CONSTRAINT idx1_unq UNIQUE (package_id, version),
    PRIMARY KEY (id)
    -- flags/enabled flags/depend/rdepend/overlay/inherit/manifest
    -- data blob /*NOT NULL*/,
);

CREATE INDEX idx2 ON ebuilds (package_id);

create table package_keywords (
    id INTEGER,
    package_id INTEGER NOT NULL,
    version INTEGER NOT NULL,
    arch_id INTEGER NOT NULL,
    keyword_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (version) REFERENCES ebuilds(id),
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (keyword_id) REFERENCES keywords(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    CONSTRAINT idx1_unq UNIQUE (
        package_id, version, arch_id, keyword_id, source_id
    ),
    PRIMARY KEY (id)
);

CREATE INDEX idx2 ON package_keywords (
    package_id, version, arch_id, keyword_id
);

create table package_masks (
    id INTEGER,
    package_id INTEGER NOT NULL,
    version CHAR NOT NULL,
    arch_id INTEGER NOT NULL,
    mask_state_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (version) REFERENCES ebuilds(id),
    FOREIGN KEY (arch_id) REFERENCES arches(id),
    FOREIGN KEY (mask_state_id) REFERENCES mask_states(id),
    FOREIGN KEY (source_id) REFERENCES sources(id),
    CONSTRAINT idx1_unq UNIQUE (
        package_id, version, arch_id, mask_state_id, source_id
    ),
    PRIMARY KEY (id)
);

/*create table licences (
    id INTEGER PRIMARY KEY,
    license_name CHAR NOT NULL
    -- url CHAR ?,
    -- content blob zipped data
);

create table licences2packages (
    id INTEGER PRIMARY KEY,
    license_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL
);

create table licences2ebuilds (
    id INTEGER PRIMARY KEY,
    license_id INTEGER NOT NULL,
    ebuild_id INTEGER NOT NULL
);

create table sets (
    id INTEGER PRIMARY KEY,
    set_name CHAR NOT NULL
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
