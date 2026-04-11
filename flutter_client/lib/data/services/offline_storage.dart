import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/artist.dart';

class OfflineStorage {
  static final OfflineStorage _instance = OfflineStorage._();
  factory OfflineStorage() => _instance;
  OfflineStorage._();

  Database? _db;
  final Lock _lock = Lock();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'spotifree_offline.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE downloaded_tracks (
            track_id TEXT PRIMARY KEY,
            file_path TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            duration INTEGER,
            downloaded_at INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE playlists (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            is_public INTEGER NOT NULL,
            server_updated_at INTEGER,
            local_updated_at INTEGER,
            deleted INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_tracks (
            playlist_id INTEGER,
            track_id TEXT,
            position INTEGER,
            PRIMARY KEY (playlist_id, track_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE liked_tracks (
            favorite_id TEXT,
            track_id TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            duration INTEGER,
            synced INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE liked_albums (
            favorite_id TEXT,
            album_id TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            synced INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE liked_artists (
            favorite_id TEXT,
            artist_id TEXT PRIMARY KEY,
            name TEXT,
            sort_name TEXT,
            synced INTEGER DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            action TEXT NOT NULL,
            entity_id TEXT,
            payload TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE liked_album_tracks (
            album_id TEXT NOT NULL,
            track_id TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            duration INTEGER,
            position INTEGER,
            PRIMARY KEY (album_id, track_id)
          )
        ''');
        
        await db.execute('CREATE INDEX idx_playlists_deleted ON playlists(deleted)');
        await db.execute('CREATE INDEX idx_playlist_tracks_playlist_id ON playlist_tracks(playlist_id)');
        await db.execute('CREATE INDEX idx_liked_tracks_track_id ON liked_tracks(track_id)');
        await db.execute('CREATE INDEX idx_liked_albums_album_id ON liked_albums(album_id)');
        await db.execute('CREATE INDEX idx_liked_artists_artist_id ON liked_artists(artist_id)');
        await db.execute('CREATE INDEX idx_sync_queue_created_at ON sync_queue(created_at)');
        await db.execute('CREATE INDEX idx_liked_album_tracks_album_id ON liked_album_tracks(album_id)');
      },
    );
  }

  Future<void> addDownloadedTrack(Track track, String filePath) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.insert('downloaded_tracks', {
        'track_id': track.id,
        'file_path': filePath,
        'title': track.title,
        'artist': track.artist,
        'duration': track.duration,
        'downloaded_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> removeDownloadedTrack(String trackId) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('downloaded_tracks', where: 'track_id = ?', whereArgs: [trackId]);
    });
  }

  Future<List<Track>> getDownloadedTracks() async {
    return await _lock.synchronized(() async {
      final db = await database;
      final maps = await db.query('downloaded_tracks');
      return maps.map((m) => Track(
        id: m['track_id'] as String,
        title: m['title'] as String,
        artist: m['artist'] as String,
        duration: m['duration'] as int?,
      )).toList();
    });
  }

  Future<Map<String, String>> getDownloadedFilePaths() async {
    return await _lock.synchronized(() async {
      final db = await database;
      final maps = await db.query('downloaded_tracks');
      return {for (var m in maps) m['track_id'] as String: m['file_path'] as String};
    });
  }

  Future<bool> isTrackDownloaded(String trackId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final res = await db.query('downloaded_tracks', where: 'track_id = ?', whereArgs: [trackId]);
      return res.isNotEmpty;
    });
  }

  Future<void> insertPlaylist(Playlist playlist) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.insert('playlists', {
        'id': playlist.id,
        'name': playlist.name,
        'description': playlist.description,
        'is_public': playlist.isPublic ? 1 : 0,
        'local_updated_at': DateTime.now().millisecondsSinceEpoch,
        'deleted': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Playlist>> getAllPlaylists() async {
    return await _lock.synchronized(() async {
      final db = await database;
      final maps = await db.query('playlists', where: 'deleted = 0');
      return maps.map((m) => Playlist(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        isPublic: (m['is_public'] as int) == 1,
        userId: 0,
      )).toList();
    });
  }

  Future<void> markPlaylistAsDeleted(String id) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.update('playlists', {'deleted': 1}, where: 'id = ?', whereArgs: [id]);
      await addToSyncQueue('playlist', 'delete', id);
    });
  }

  Future<void> permanentlyDeletePlaylist(String id) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
      await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [id]);
    });
  }

  Future<void> savePlaylistTracks(String playlistId, List<Track> tracks) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
      for (int i = 0; i < tracks.length; i++) {
        await db.insert('playlist_tracks', {
          'playlist_id': playlistId,
          'track_id': tracks[i].id,
          'position': i,
        });
        await _ensureTrackMetadata(tracks[i]);
      }
    });
  }

  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final result = await db.rawQuery('''
        SELECT t.track_id, t.title, t.artist, t.duration
        FROM downloaded_tracks t
        JOIN playlist_tracks pt ON t.track_id = pt.track_id
        WHERE pt.playlist_id = ?
        ORDER BY pt.position ASC
      ''', [playlistId]);
      return result.map((m) => Track(
        id: m['track_id'] as String,
        title: m['title'] as String,
        artist: m['artist'] as String,
        duration: m['duration'] as int?,
      )).toList();
    });
  }

  Future<void> _ensureTrackMetadata(Track track) async {
    final db = await database;
    await db.insert('downloaded_tracks', {
      'track_id': track.id,
      'file_path': '',
      'title': track.title,
      'artist': track.artist,
      'duration': track.duration,
      'downloaded_at': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> addLikedTrack(String favoriteId, Track track) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.insert('liked_tracks', {
        'favorite_id': favoriteId,
        'track_id': track.id,
        'title': track.title,
        'artist': track.artist,
        'duration': track.duration,
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> removeLikedTrack(String favoriteId) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('liked_tracks', where: 'favorite_id = ?', whereArgs: [favoriteId]);
    });
  }

  Future<List<Map<String, dynamic>>> getLikedTracks() async {
    return await _lock.synchronized(() async {
      final db = await database;
      final maps = await db.query('liked_tracks');
      return maps.map((m) => {
        'id': m['favorite_id'] as String,
        'track': Track(
          id: m['track_id'] as String,
          title: m['title'] as String,
          artist: m['artist'] as String,
          duration: m['duration'] as int?,
        ),
      }).toList();
    });
  }

  Future<bool> isTrackLiked(String trackId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final res = await db.query('liked_tracks', where: 'track_id = ?', whereArgs: [trackId]);
      return res.isNotEmpty;
    });
  }

  Future<String?> getFavoriteIdForTrack(String trackId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final res = await db.query('liked_tracks', where: 'track_id = ?', whereArgs: [trackId]);
      if (res.isNotEmpty) return res.first['favorite_id'] as String?;
      return null;
    });
  }

  Future<void> addLikedAlbum(String favoriteId, Album album) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.insert('liked_albums', {
        'favorite_id': favoriteId,
        'album_id': album.id,
        'title': album.title,
        'artist': album.artist,
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> removeLikedAlbum(String albumId) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('liked_albums', where: 'album_id = ?', whereArgs: [albumId]);
    });
  }

  Future<List<Album>> getLikedAlbums() async {
    return await _lock.synchronized(() async {
      final db = await database;
      final maps = await db.query('liked_albums');
      return maps.map((m) => Album(
        id: m['album_id'] as String,
        title: m['title'] as String,
        artist: m['artist'] as String?,
      )).toList();
    });
  }

  Future<String?> getFavoriteIdForAlbum(String albumId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final res = await db.query('liked_albums', where: 'album_id = ?', whereArgs: [albumId]);
      if (res.isNotEmpty) return res.first['favorite_id'] as String?;
      return null;
    });
  }

  Future<void> addLikedArtist(String favoriteId, Artist artist) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.insert('liked_artists', {
        'favorite_id': favoriteId,
        'artist_id': artist.id,
        'name': artist.name,
        'sort_name': artist.sortName,
        'synced': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> removeLikedArtist(String artistId) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('liked_artists', where: 'artist_id = ?', whereArgs: [artistId]);
    });
  }

  Future<List<Artist>> getLikedArtists() async {
    return await _lock.synchronized(() async {
      final db = await database;
      final maps = await db.query('liked_artists');
      return maps.map((m) => Artist(
        id: m['artist_id'] as String,
        name: m['name'] as String,
        sortName: m['sort_name'] as String?,
      )).toList();
    });
  }

  Future<String?> getFavoriteIdForArtist(String artistId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final res = await db.query('liked_artists', where: 'artist_id = ?', whereArgs: [artistId]);
      if (res.isNotEmpty) return res.first['favorite_id'] as String?;
      return null;
    });
  }

  Future<void> addToSyncQueue(String entityType, String action, String? entityId, {String? payload}) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.insert('sync_queue', {
        'entity_type': entityType,
        'action': action,
        'entity_id': entityId,
        'payload': payload,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    return await _lock.synchronized(() async {
      final db = await database;
      return await db.query('sync_queue', orderBy: 'created_at ASC');
    });
  }

  Future<void> removeSyncItem(int id) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> clearAll() async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('downloaded_tracks');
      await db.delete('playlists');
      await db.delete('playlist_tracks');
      await db.delete('liked_tracks');
      await db.delete('liked_albums');
      await db.delete('liked_artists');
      await db.delete('sync_queue');
    });
  }

  Future<void> saveLikedAlbumTracks(String albumId, List<Track> tracks) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('liked_album_tracks', where: 'album_id = ?', whereArgs: [albumId]);
      for (int i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        await db.insert('liked_album_tracks', {
          'album_id': albumId,
          'track_id': track.id,
          'title': track.title,
          'artist': track.artist,
          'duration': track.duration,
          'position': i,
        });
      }
    });
  }

  Future<List<Track>> getLikedAlbumTracks(String albumId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final result = await db.query(
        'liked_album_tracks',
        where: 'album_id = ?',
        whereArgs: [albumId],
        orderBy: 'position ASC',
      );
      return result.map((row) => Track(
        id: row['track_id'] as String,
        title: row['title'] as String,
        artist: row['artist'] as String,
        duration: row['duration'] as int?,
      )).toList();
    });
  }

  Future<void> removeLikedAlbumTracks(String albumId) async {
    await _lock.synchronized(() async {
      final db = await database;
      await db.delete('liked_album_tracks', where: 'album_id = ?', whereArgs: [albumId]);
    });
  }

  Future<bool> isAlbumLiked(String albumId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final res = await db.query('liked_albums', where: 'album_id = ?', whereArgs: [albumId]);
      return res.isNotEmpty;
    });
  }

  Future<dynamic> isArtistLiked(String artistId) async {
    return await _lock.synchronized(() async {
      final db = await database;
      final res = await db.query('liked_artists', where: 'artist_id = ?', whereArgs: [artistId]);
      return res.isNotEmpty;
    });
  }
}