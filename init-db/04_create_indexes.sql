\set ON_ERROR_STOP 1
BEGIN;

CREATE UNIQUE INDEX artist_idx_gid ON artist (gid);
CREATE INDEX artist_idx_name ON artist (name);
CREATE INDEX artist_idx_sort_name ON artist (sort_name);
CREATE INDEX artist_idx_area ON artist (area);
CREATE INDEX artist_idx_begin_area ON artist (begin_area);
CREATE INDEX artist_idx_end_area ON artist (end_area);

CREATE UNIQUE INDEX artist_credit_idx_gid ON artist_credit (gid);
CREATE INDEX artist_credit_name_idx_artist ON artist_credit_name (artist);

CREATE UNIQUE INDEX release_group_idx_gid ON release_group (gid);
CREATE INDEX release_group_idx_name ON release_group (name);
CREATE INDEX release_group_idx_artist_credit ON release_group (artist_credit);

CREATE UNIQUE INDEX release_idx_gid ON release (gid);
CREATE INDEX release_idx_name ON release (name);
CREATE INDEX release_idx_release_group ON release (release_group);
CREATE INDEX release_idx_artist_credit ON release (artist_credit);

CREATE INDEX release_country_idx_country ON release_country (country);

CREATE UNIQUE INDEX medium_idx_gid ON medium (gid);
CREATE INDEX medium_idx_release ON medium (release);

CREATE UNIQUE INDEX recording_idx_gid ON recording (gid);
CREATE INDEX recording_idx_name ON recording (name);
CREATE INDEX recording_idx_artist_credit ON recording (artist_credit);

CREATE UNIQUE INDEX track_idx_gid ON track (gid);
CREATE INDEX track_idx_recording ON track (recording);
CREATE INDEX track_idx_artist_credit ON track (artist_credit);
CREATE INDEX track_idx_medium ON track (medium);

CREATE INDEX isrc_idx_isrc ON isrc (isrc);
CREATE INDEX isrc_idx_recording ON isrc (recording);

CREATE UNIQUE INDEX tag_idx_name ON tag (name);

CREATE INDEX artist_tag_idx_tag ON artist_tag (tag);
CREATE INDEX release_group_tag_idx_tag ON release_group_tag (tag);
CREATE INDEX recording_tag_idx_tag ON recording_tag (tag);

CREATE INDEX rating_raw_idx_entity ON rating_raw (entity_type, entity_id);

CREATE INDEX idx_playlist_tracks_playlist ON playlist_tracks(playlist_id);
CREATE INDEX idx_download_tasks_status ON download_tasks(status);

COMMIT;

-- Indeksy trigramowe (poza transakcją, aby działało CONCURRENTLY)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX CONCURRENTLY artist_name_trgm ON artist USING gin (name gin_trgm_ops);
CREATE INDEX CONCURRENTLY release_group_name_trgm ON release_group USING gin (name gin_trgm_ops);
CREATE INDEX CONCURRENTLY recording_name_trgm ON recording USING gin (name gin_trgm_ops);