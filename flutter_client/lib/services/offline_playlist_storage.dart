import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/models/track.dart';

class OfflinePlaylistStorage {
  static final OfflinePlaylistStorage _instance = OfflinePlaylistStorage._internal();
  factory OfflinePlaylistStorage() => _instance;
  OfflinePlaylistStorage._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_playlists.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE playlists(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            is_public INTEGER NOT NULL,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE tracks(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            duration INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE playlist_tracks(
            playlist_id INTEGER,
            track_id TEXT,
            position INTEGER,
            PRIMARY KEY (playlist_id, track_id),
            FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE,
            FOREIGN KEY (track_id) REFERENCES tracks(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<void> insertPlaylist(Playlist playlist) async {
    final db = await database;
    await db.insert(
      'playlists',
      {
        'id': playlist.id,
        'name': playlist.name,
        'description': playlist.description,
        'is_public': playlist.isPublic ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePlaylist(int id) async {
    final db = await database;
    await db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Playlist>> getAllPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('playlists');
    return maps.map((map) => Playlist(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      isPublic: (map['is_public'] as int) == 1,
      userId: 0,
    )).toList();
  }

  Future<void> insertTrack(Track track) async {
    final db = await database;
    await db.insert(
      'tracks',
      {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'duration': track.duration,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTracks(List<Track> tracks) async {
    for (final track in tracks) {
      await insertTrack(track);
    }
  }

  Future<Track?> getTrack(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    final map = result.first;
    return Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      duration: map['duration'] as int?,
    );
  }

  Future<void> savePlaylistTracks(int playlistId, List<Track> tracks) async {
    final db = await database;
    // Remove old associations
    await db.delete('playlist_tracks', where: 'playlist_id = ?', whereArgs: [playlistId]);
    // Insert tracks metadata and associations
    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      await insertTrack(track);
      await db.insert('playlist_tracks', {
        'playlist_id': playlistId,
        'track_id': track.id,
        'position': i,
      });
    }
  }

  Future<List<Track>> getPlaylistTracks(int playlistId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.* FROM tracks t
      JOIN playlist_tracks pt ON t.id = pt.track_id
      WHERE pt.playlist_id = ?
      ORDER BY pt.position ASC
    ''', [playlistId]);
    return result.map((map) => Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      duration: map['duration'] as int?,
    )).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('playlist_tracks');
    await db.delete('tracks');
    await db.delete('playlists');
  }
}