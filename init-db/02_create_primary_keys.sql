\set ON_ERROR_STOP 1
BEGIN;

ALTER TABLE artist_type ADD PRIMARY KEY (id);
ALTER TABLE gender ADD PRIMARY KEY (id);
ALTER TABLE area ADD PRIMARY KEY (id);
ALTER TABLE language ADD PRIMARY KEY (id);
ALTER TABLE script ADD PRIMARY KEY (id);
ALTER TABLE release_group_primary_type ADD PRIMARY KEY (id);
ALTER TABLE release_group_secondary_type ADD PRIMARY KEY (id);
ALTER TABLE release_status ADD PRIMARY KEY (id);
ALTER TABLE release_packaging ADD PRIMARY KEY (id);
ALTER TABLE medium_format ADD PRIMARY KEY (id);

ALTER TABLE artist ADD PRIMARY KEY (id);
ALTER TABLE artist_credit ADD PRIMARY KEY (id);
ALTER TABLE artist_credit_name ADD PRIMARY KEY (artist_credit, position);
ALTER TABLE release_group ADD PRIMARY KEY (id);
ALTER TABLE release_group_secondary_type_join ADD PRIMARY KEY (release_group, secondary_type);
ALTER TABLE release ADD PRIMARY KEY (id);
ALTER TABLE release_country ADD PRIMARY KEY (release, country);
ALTER TABLE release_unknown_country ADD PRIMARY KEY (release);
ALTER TABLE release_meta ADD PRIMARY KEY (id);
ALTER TABLE medium ADD PRIMARY KEY (id);
ALTER TABLE recording ADD PRIMARY KEY (id);
ALTER TABLE track ADD PRIMARY KEY (id);
ALTER TABLE isrc ADD PRIMARY KEY (id);
ALTER TABLE tag ADD PRIMARY KEY (id);
ALTER TABLE artist_tag ADD PRIMARY KEY (artist, tag);
ALTER TABLE release_group_tag ADD PRIMARY KEY (release_group, tag);
ALTER TABLE recording_tag ADD PRIMARY KEY (recording, tag);
ALTER TABLE rating_raw ADD PRIMARY KEY (entity_type, entity_id, editor);

ALTER TABLE artist_gid_redirect ADD PRIMARY KEY (gid);
ALTER TABLE release_group_gid_redirect ADD PRIMARY KEY (gid);
ALTER TABLE release_gid_redirect ADD PRIMARY KEY (gid);
ALTER TABLE recording_gid_redirect ADD PRIMARY KEY (gid);
ALTER TABLE medium_gid_redirect ADD PRIMARY KEY (gid);
ALTER TABLE track_gid_redirect ADD PRIMARY KEY (gid);

COMMIT;