BEGIN TRANSACTION;

create table categories (
    id INTEGER,
    category_name text UNIQUE NOT NULL,
    description text NOT NULL,
    PRIMARY KEY (id)
);

create table packages (
    id INTEGER,
    category_id INTEGER NOT NULL,
    package_name text NOT NULL,
    description text NOT NULL DEFAULT '', /* default is temporary? workaround*/
    homepage text NOT NULL DEFAULT '', /* default is temporary? workaround*/
    CONSTRAINT unq_cat_id8package UNIQUE (category_id, package_name),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    PRIMARY KEY (id)
);

create table persons (
    id INTEGER,
    name text,
    email text UNIQUE NOT NULL,
    nickname text UNIQUE,
    CONSTRAINT unq_name8email UNIQUE (name, email),
    PRIMARY KEY (id)
);

create table responsibilities (
    id INTEGER,
    responsibility text UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

create table persons2responsibilities (
    id INTEGER,
    person_id INTEGER NOT NULL,
    responsibility_id INTEGER NOT NULL,
    FOREIGN KEY (person_id) REFERENCES persons(id),
    FOREIGN KEY (responsibility_id) REFERENCES responsibilities(id),
    CONSTRAINT unq_perdon_id8resp UNIQUE (person_id, responsibility_id),
    PRIMARY KEY (id)
);

create table maintainers2packages (
    id INTEGER,
    package_id INTEGER NOT NULL,
    maintainer_id INTEGER NOT NULL,
    FOREIGN KEY (maintainer_id) REFERENCES persons2responsibilities(id),
    FOREIGN KEY (package_id) REFERENCES packages(id),
    PRIMARY KEY (id)
);

create table ebuilds (
    id INTEGER PRIMARY KEY,
    package_id INTEGER NOT NULL,
    version text NOT NULL,
    licence text NOT NULL,
    keyword_id INTEGER NOT NULL,
    architecture INTEGER NOT NULL,
    mtime INTEGER NOT NULL,
    mauthor text NOT NULL,
    eapi INTEGER /*NOT NULL*/,
    slot INTEGER NOT NULL
    -- data blob /*NOT NULL*/,
    -- depend TODO
    -- rdepend TODO
    -- sha1/md5 INTEGER NOT NULL
    -- overlay?
    -- size of dwonloads?
    -- compile_flags?
);

Create table use_flags (
    id INTEGER PRIMARY KEY,
    flag_name text NOT NULL,
    flag_description text NOT NULL
);

Create table use_flags2ebuilds (
    id INTEGER PRIMARY KEY,
    flag_id INTEGER NOT NULL,
    ebuild_id INTEGER NOT NULL
);

Create table architectures (
    id INTEGER PRIMARY KEY,
    architecture text UNIQUE NOT NULL
    -- smth else?
);

Create table ebuilds2architectures (
    id INTEGER PRIMARY KEY,
    ebuild_id INTEGER NOT NULL,
    architecture_id INTEGER NOT NULL
);

Create table keywords (
    id INTEGER PRIMARY KEY,
    keyword text UNIQUE NOT NULL/*,
    keyword_description text NOT NULL*/
);

Create table keywords2architectures (
    id INTEGER PRIMARY KEY,
    ebuild_architecture_id INTEGER NOT NULL,
    keyword_id INTEGER NOT NULL
);

create table licences (
    id INTEGER PRIMARY KEY,
    license_name text NOT NULL
    -- url text ?,
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
    set_name text NOT NULL
);

create table sets_content (
    id INTEGER PRIMARY KEY,
    set_id text INTEGER NOT NULL,
    package_id text INTEGER NOT NULL
);

COMMIT;
