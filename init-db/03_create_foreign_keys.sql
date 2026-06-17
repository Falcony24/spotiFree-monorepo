\set ON_ERROR_STOP 1
BEGIN;

-- Klucze obce dla tabel użytkownika
ALTER TABLE favorite_artists ADD CONSTRAINT fk_favorite_artists_artist FOREIGN KEY (artist_id) REFERENCES artist(id) ON DELETE CASCADE;
ALTER TABLE favorite_albums ADD CONSTRAINT fk_favorite_albums_album FOREIGN KEY (album_id) REFERENCES release_group(id) ON DELETE CASCADE;
ALTER TABLE favorite_tracks ADD CONSTRAINT fk_favorite_tracks_track FOREIGN KEY (track_id) REFERENCES recording(id) ON DELETE CASCADE;

-- Opcjonalnie: klucze obce wewnątrz głównych tabel MB (jeśli potrzebujesz integralności)
-- (w oryginalnym schemacie MB są one pomijane przy imporcie przez session_replication_role=replica)

COMMIT;