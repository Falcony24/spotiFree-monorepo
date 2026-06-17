\set ON_ERROR_STOP 1
BEGIN;

-- =====================================================
-- Dictionary
-- =====================================================

CREATE TABLE artist_type ( id SERIAL, name VARCHAR(255) NOT NULL, parent INTEGER, child_order INTEGER NOT NULL DEFAULT 0, description TEXT, gid uuid NOT NULL );
CREATE TABLE gender ( id SERIAL, name VARCHAR(255) NOT NULL, parent INTEGER, child_order INTEGER NOT NULL DEFAULT 0, description TEXT, gid uuid NOT NULL );
CREATE TABLE area ( id SERIAL, gid uuid NOT NULL, name VARCHAR NOT NULL, type INTEGER, edits_pending INTEGER NOT NULL DEFAULT 0, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(), begin_date_year SMALLINT, begin_date_month SMALLINT, begin_date_day SMALLINT, end_date_year SMALLINT, end_date_month SMALLINT, end_date_day SMALLINT, ended BOOLEAN NOT NULL DEFAULT FALSE, comment VARCHAR(255) NOT NULL DEFAULT '' );
CREATE TABLE language ( id SERIAL, iso_code_2t CHAR(3), iso_code_2b CHAR(3), iso_code_1 CHAR(2), name VARCHAR(100) NOT NULL, frequency SMALLINT NOT NULL DEFAULT 0, iso_code_3 CHAR(3) );
CREATE TABLE script ( id SERIAL, iso_code CHAR(4) NOT NULL, iso_number CHAR(3) NOT NULL, name VARCHAR(100) NOT NULL, frequency SMALLINT NOT NULL DEFAULT 0 );
CREATE TABLE release_group_primary_type ( id SERIAL, name VARCHAR(255) NOT NULL, parent INTEGER, child_order INTEGER NOT NULL DEFAULT 0, description TEXT, gid uuid NOT NULL );
CREATE TABLE release_group_secondary_type ( id SERIAL NOT NULL, name TEXT NOT NULL, parent INTEGER, child_order INTEGER NOT NULL DEFAULT 0, description TEXT, gid uuid NOT NULL );
CREATE TABLE release_status ( id SERIAL, name VARCHAR(255) NOT NULL, parent INTEGER, child_order INTEGER NOT NULL DEFAULT 0, description TEXT, gid uuid NOT NULL );
CREATE TABLE release_packaging ( id SERIAL, name VARCHAR(255) NOT NULL, parent INTEGER, child_order INTEGER NOT NULL DEFAULT 0, description TEXT, gid uuid NOT NULL );
CREATE TABLE medium_format ( id SERIAL, name VARCHAR(100) NOT NULL, parent INTEGER, child_order INTEGER NOT NULL DEFAULT 0, year SMALLINT, has_discids BOOLEAN NOT NULL DEFAULT FALSE, description TEXT, gid uuid NOT NULL );

-- =====================================================
-- Main (oryginalne MusicBrainz)
-- =====================================================

CREATE TABLE artist ( id SERIAL, gid UUID NOT NULL, name VARCHAR NOT NULL, sort_name VARCHAR NOT NULL, begin_date_year SMALLINT, begin_date_month SMALLINT, begin_date_day SMALLINT, end_date_year SMALLINT, end_date_month SMALLINT, end_date_day SMALLINT, type INTEGER, area INTEGER, gender INTEGER, comment VARCHAR(255) NOT NULL DEFAULT '', edits_pending INTEGER NOT NULL DEFAULT 0, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(), ended BOOLEAN NOT NULL DEFAULT FALSE, begin_area INTEGER, end_area INTEGER );

CREATE TABLE artist_credit ( id SERIAL, name VARCHAR NOT NULL, artist_count SMALLINT NOT NULL, ref_count INTEGER DEFAULT 0, created TIMESTAMP WITH TIME ZONE DEFAULT NOW(), edits_pending INTEGER NOT NULL DEFAULT 0, gid UUID NOT NULL );

CREATE TABLE artist_credit_name ( artist_credit INTEGER NOT NULL, position SMALLINT NOT NULL, artist INTEGER NOT NULL, name VARCHAR NOT NULL, join_phrase TEXT NOT NULL DEFAULT '' );

CREATE TABLE release_group ( id SERIAL, gid UUID NOT NULL, name VARCHAR NOT NULL, artist_credit INTEGER NOT NULL, type INTEGER, comment VARCHAR(255) NOT NULL DEFAULT '', edits_pending INTEGER NOT NULL DEFAULT 0, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

CREATE TABLE release_group_secondary_type_join ( release_group INTEGER NOT NULL, secondary_type INTEGER NOT NULL, created TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now() );

CREATE TABLE release ( id SERIAL, gid UUID NOT NULL, name VARCHAR NOT NULL, artist_credit INTEGER NOT NULL, release_group INTEGER NOT NULL, status INTEGER, packaging INTEGER, language INTEGER, script INTEGER, barcode VARCHAR(255), comment VARCHAR(255) NOT NULL DEFAULT '', edits_pending INTEGER NOT NULL DEFAULT 0, quality SMALLINT NOT NULL DEFAULT -1, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

CREATE TABLE release_country ( release INTEGER NOT NULL, country INTEGER NOT NULL, date_year SMALLINT, date_month SMALLINT, date_day SMALLINT );

CREATE TABLE release_unknown_country ( release INTEGER NOT NULL, date_year SMALLINT, date_month SMALLINT, date_day SMALLINT );

CREATE TABLE release_meta ( id INTEGER NOT NULL, date_added TIMESTAMP WITH TIME ZONE DEFAULT NOW(), info_url VARCHAR(255), amazon_asin VARCHAR(10), cover_art_presence TEXT NOT NULL DEFAULT 'absent' );

CREATE TABLE medium ( id SERIAL, release INTEGER NOT NULL, position INTEGER NOT NULL, format INTEGER, name VARCHAR NOT NULL DEFAULT '', edits_pending INTEGER NOT NULL DEFAULT 0, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(), track_count INTEGER NOT NULL DEFAULT 0, gid UUID NOT NULL );

CREATE TABLE recording ( id SERIAL, gid UUID NOT NULL, name VARCHAR NOT NULL, artist_credit INTEGER NOT NULL, length INTEGER CHECK (length IS NULL OR length > 0), comment VARCHAR(255) NOT NULL DEFAULT '', edits_pending INTEGER NOT NULL DEFAULT 0, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(), video BOOLEAN NOT NULL DEFAULT FALSE );

CREATE TABLE track ( id SERIAL, gid UUID NOT NULL, recording INTEGER NOT NULL, medium INTEGER NOT NULL, position INTEGER NOT NULL, number TEXT NOT NULL, name VARCHAR NOT NULL, artist_credit INTEGER NOT NULL, length INTEGER CHECK (length IS NULL OR length > 0), edits_pending INTEGER NOT NULL DEFAULT 0, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(), is_data_track BOOLEAN NOT NULL DEFAULT FALSE );

CREATE TABLE isrc ( id SERIAL, recording INTEGER NOT NULL, isrc CHAR(12) NOT NULL, source SMALLINT, edits_pending INTEGER NOT NULL DEFAULT 0, created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

CREATE TABLE tag ( id SERIAL, name VARCHAR(255) NOT NULL, ref_count INTEGER NOT NULL DEFAULT 0 );

CREATE TABLE artist_tag ( artist INTEGER NOT NULL, tag INTEGER NOT NULL, count INTEGER NOT NULL, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

CREATE TABLE release_group_tag ( release_group INTEGER NOT NULL, tag INTEGER NOT NULL, count INTEGER NOT NULL, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

CREATE TABLE recording_tag ( recording INTEGER NOT NULL, tag INTEGER NOT NULL, count INTEGER NOT NULL, last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

CREATE TABLE rating_raw ( entity_type VARCHAR(20) NOT NULL, entity_id INTEGER NOT NULL, editor INTEGER NOT NULL, rating SMALLINT NOT NULL CHECK (rating >= 0 AND rating <= 100), created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

-- =====================================================
-- Redirecty GID 
-- =====================================================

CREATE TABLE artist_gid_redirect ( gid UUID NOT NULL, new_id INTEGER NOT NULL, created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );
CREATE TABLE release_group_gid_redirect ( gid UUID NOT NULL, new_id INTEGER NOT NULL, created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );
CREATE TABLE release_gid_redirect ( gid UUID NOT NULL, new_id INTEGER NOT NULL, created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );
CREATE TABLE recording_gid_redirect ( gid UUID NOT NULL, new_id INTEGER NOT NULL, created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );
CREATE TABLE medium_gid_redirect ( gid UUID NOT NULL, new_id INTEGER NOT NULL, created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );
CREATE TABLE track_gid_redirect ( gid UUID NOT NULL, new_id INTEGER NOT NULL, created TIMESTAMP WITH TIME ZONE DEFAULT NOW() );

-- =====================================================
-- Użytkownicy i playlisty (na razie bez kluczy obcych do MB)
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    username VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE playlists (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE playlist_tracks (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    playlist_id INT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
    track_mbid UUID NOT NULL,
    position INT NOT NULL,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (playlist_id, track_mbid)
);

-- Tabele ulubionych – NA RAZIE BEZ FOREIGN KEY, dodamy później
CREATE TABLE favorite_artists (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artist_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, artist_id)
);

CREATE TABLE favorite_albums (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    album_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, album_id)
);

CREATE TABLE favorite_tracks (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    track_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE (user_id, track_id)
);

CREATE TABLE download_tasks (
    id SERIAL PRIMARY KEY,
    gid UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    track_mbid UUID NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    source_url VARCHAR(255),
    retries INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

COMMIT;