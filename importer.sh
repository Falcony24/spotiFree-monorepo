#!/bin/sh
set -e

echo "Waiting for database to be ready..."
until psql -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

echo "Checking if data already imported..."
COUNT=$(psql -t -c "SELECT COUNT(*) FROM artist;")
if [ "$COUNT" -gt 1000 ]; then
  echo "Data already exists (artist count = $COUNT). Skipping import."
  exit 0
fi

echo "Starting import process..."

cd /dumps

# if [ ! -d "mbdump" ]; then
#   echo "Extracting mbdump.tar.bz2..."
#   tar -xjf mbdump.tar.bz2
# fi

# if [ ! -d "mbdump-derived" ] && [ -f "mbdump-derived.tar.bz2" ]; then
#   echo "Extracting mbdump-derived.tar.bz2..."
#   tar -xjf mbdump-derived.tar.bz2
# fi

# Wyłącz tymczasowo sprawdzanie kluczy obcych – przyspiesza import
psql -c "SET session_replication_role = replica;"

import_table() {
  table=$1
  file="/dumps/$table"
  if [ -f "$file" ]; then
    echo "Importing $table ..."
    psql -c "\copy $table FROM '$file' WITH NULL AS '\N' DELIMITER E'\t' QUOTE E'\b' CSV;"
  else
    echo "File $file not found, skipping $table"
  fi
}


import_table "artist_type"
import_table "gender"
import_table "language"
import_table "script"
import_table "release_group_primary_type"
import_table "release_group_secondary_type"
import_table "release_status"
import_table "release_packaging"
import_table "medium_format"

import_table "area"

import_table "artist"
import_table "artist_credit"
import_table "release_group"
import_table "release"
import_table "medium"
import_table "recording"

import_table "artist_credit_name"
import_table "release_group_secondary_type_join"
import_table "release_country"
import_table "release_unknown_country"
import_table "release_meta"
import_table "track"
import_table "isrc"
import_table "tag"
import_table "artist_tag"
import_table "release_group_tag"
import_table "recording_tag"

# import_table "artist_gid_redirect"
# import_table "release_group_gid_redirect"
# import_table "release_gid_redirect"
# import_table "recording_gid_redirect"
# import_table "medium_gid_redirect"
# import_table "track_gid_redirect"

# if [ -d "/dumps/mbdump-derived" ]; then
#   import_table "artist_rating_raw"
#   import_table "release_group_rating_raw"
#   import_table "recording_rating_raw"
# fi

psql -c "SET session_replication_role = DEFAULT;"

echo "Import completed successfully!"