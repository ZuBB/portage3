BEGIN TRANSACTION;

create table _note_eapi_0_nf (
    -- this is a table with ids of ebuilds that does not have
    -- any eapi version inside, ie 0 is assumed.
    -- originally I use '0_NF' marker for them.
    -- in the main table they all have id of 'eapi verion 0' record
    id INTEGER,
    ebuild_id INTEGER NOT NULL,
    FOREIGN KEY (ebuild_id) REFERENCES ebuilds(id),
    PRIMARY KEY (id)
);

create table _note_email_mn (
    -- this is a table with ids of packages that have
    -- 'maintainer-needed@gentoo.org' email as maintainer's email
    id INTEGER,
    package_id INTEGER NOT NULL,
    FOREIGN KEY (package_id) REFERENCES packages(id),
    PRIMARY KEY (id)
);

COMMIT;
