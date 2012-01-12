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

COMMIT;
