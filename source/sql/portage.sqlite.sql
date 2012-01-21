BEGIN TRANSACTION;

create table architectures (
    id INTEGER,
    architecture VARCHAR UNIQUE NOT NULL,
    PRIMARY KEY (id)
    -- smth else?
);

create table platforms (
    id INTEGER,
    platform_name VARCHAR UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

create table profiles (
    id INTEGER,
    profile_name VARCHAR NOT NULL,
    architecture_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    FOREIGN KEY (architecture_id) REFERENCES architectures(id),
    FOREIGN KEY (status_id) REFERENCES profile_statuses(id),
    CONSTRAINT idx1_unq UNIQUE (profile_name, architecture_id, status_id),
    PRIMARY KEY (id)
);

create table prefix_profiles (
    id INTEGER,
    profile_name VARCHAR NOT NULL,
    architecture_id INTEGER NOT NULL,
    platform_id INTEGER NOT NULL,
    status_id INTEGER NOT NULL,
    FOREIGN KEY (architecture_id) REFERENCES architectures(id),
    FOREIGN KEY (status_id) REFERENCES profile_statuses(id),
    FOREIGN KEY (platform_id) REFERENCES platforms(id),
    CONSTRAINT idx1_unq UNIQUE (profile_name, architecture_id, platform_id, status_id),
    PRIMARY KEY (id)
);

create table profile_statuses (
    id INTEGER,
    profile_status VARCHAR UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

create table keywords (
    id INTEGER PRIMARY KEY,
    keyword VARCHAR UNIQUE NOT NULL/*,
    keyword_description VARCHAR NOT NULL*/
);

create table categories (
    id INTEGER,
    category_name VARCHAR UNIQUE NOT NULL,
    description VARCHAR NOT NULL,
    PRIMARY KEY (id)
);

create table packages (
    id INTEGER,
    category_id INTEGER NOT NULL,
    package_name VARCHAR NOT NULL,
    description VARCHAR NOT NULL,
    homepage VARCHAR NOT NULL,
    CONSTRAINT idx1_unq UNIQUE (category_id, package_name),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    PRIMARY KEY (id)
);

create table eapis (
    id INTEGER,
    eapi_version INTEGER UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

create table all_use_flags (
    id INTEGER,
    flag_name VARCHAR UNIQUE NOT NULL,
    flag_description VARCHAR UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

create table use_flags_states (
    id INTEGER,
    flag_state VARCHAR UNIQUE NOT NULL,
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
    name VARCHAR,
    email VARCHAR UNIQUE NOT NULL,
    nickname VARCHAR UNIQUE,
    CONSTRAINT idx1_unq UNIQUE (name, email, nickname),
    PRIMARY KEY (id)
);

create table roles (
    id INTEGER,
    role VARCHAR UNIQUE NOT NULL,
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
);

create table ebuilds (
    id INTEGER,
    package_id INTEGER NOT NULL,
    version VARCHAR NOT NULL,
    license VARCHAR NOT NULL,
    mtime VARCHAR NOT NULL,
    mauthor VARCHAR NOT NULL,
    eapi_id INTEGER NOT NULL,
    slot VARCHAR NOT NULL,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    FOREIGN KEY (eapi_id) REFERENCES eapis(id),
    -- flags?
    -- enabled flags?
    -- depend
    -- rdepend
    -- overlay?
    -- inherit
    CONSTRAINT idx1_unq UNIQUE (package_id, version),
    PRIMARY KEY (id)
    -- sha1/md5 INTEGER NOT NULL
    -- size of dwonloads?
    -- data blob /*NOT NULL*/,
);

create table ebuilds2architectures (
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    architecture_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    FOREIGN KEY (architecture_id) REFERENCES architectures(id),
    CONSTRAINT idx1_unq UNIQUE (ebuild_id, architecture_id),
    PRIMARY KEY (id)
);

create table ebuild_arch2keywords (
    id INTEGER,
    ebuild_arch_id INTEGER NOT NULL,
    keyword_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_arch_id) REFERENCES ebuilds2architectures(id),
    FOREIGN KEY (keyword_id) REFERENCES keywords(id),
    CONSTRAINT idx1_unq UNIQUE (ebuild_arch_id, keyword_id),
    PRIMARY KEY (id)
);

create table licences (
    id INTEGER PRIMARY KEY,
    license_name VARCHAR NOT NULL
    -- url VARCHAR ?,
    -- content blob /*zipped data*/ ?
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
    set_name VARCHAR NOT NULL
);

create table sets_content (
    id INTEGER PRIMARY KEY,
    set_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL
);

COMMIT;
