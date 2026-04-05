import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:frontend/models/track.dart';

class OfflineLikedStorage {
  static final OfflineLikedStorage _instance = OfflineLikedStorage._internal();
  factory OfflineLikedStorage() => _instance;
  OfflineLikedStorage._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_liked.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE liked_tracks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            favorite_id INTEGER,
            track_id TEXT NOT NULL,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            duration INTEGER,
            UNIQUE(track_id)
          )
        ''');
      },
    );
  }

  Future<void> saveLikedTracks(List<Map<String, dynamic>> likedItems) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('liked_tracks');
      for (final item in likedItems) {
        final track = item['track'] as Track;
        await txn.insert('liked_tracks', {
          'favorite_id': item['id'],
          'track_id': track.id,
          'title': track.title,
          'artist': track.artist,
          'duration': track.duration,
        });
      }
    });
  }

  Future<void> addLikedTrack(int favoriteId, Track track) async {
    final db = await database;
    await db.insert(
      'liked_tracks',
      {
        'favorite_id': favoriteId,
        'track_id': track.id,
        'title': track.title,
        'artist': track.artist,
        'duration': track.duration,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeLikedTrack(String trackId) async {
    final db = await database;
    await db.delete('liked_tracks', where: 'track_id = ?', whereArgs: [trackId]);
  }

  Future<List<Map<String, dynamic>>> loadLikedTracks() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('liked_tracks');
    return results.map((map) {
      final track = Track(
        id: map['track_id'] as String,
        title: map['title'] as String,
        artist: map['artist'] as String,
        duration: map['duration'] as int?,
      );
      return {
        'id': map['favorite_id'],
        'track': track,
      };
    }).toList();
  }

  Future<bool> isLiked(String trackId) async {
    final db = await database;
    final result = await db.query(
      'liked_tracks',
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
    return result.isNotEmpty;
  }

  Future<int?> getFavoriteId(String trackId) async {
    final db = await database;
    final result = await db.query(
      'liked_tracks',
      where: 'track_id = ?',
      whereArgs: [trackId],
    );
    if (result.isNotEmpty) return result.first['favorite_id'] as int?;
    return null;
  }
}