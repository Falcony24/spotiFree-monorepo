import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/download_storage.dart';

class SqliteDownloadStorage implements DownloadStorage {
  Database? _database;

  @override
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
      if (kDebugMode) {
        print('File exists: $dbPath');
      }
    final path = join(dbPath, 'downloaded_tracks.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE downloaded_tracks(id TEXT PRIMARY KEY, title TEXT, artist TEXT, file_path TEXT, duration INTEGER)',
        );
      },
    );
  }

  @override
  Future<List<Track>> loadTracks() async {
    if (_database == null) return [];
    final maps = await _database!.query('downloaded_tracks');
    return maps.map((map) => Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      duration: map['duration'] as int?,
    )).toList();
  }

  @override
  Future<Map<String, String>> loadFilePaths() async {
    if (_database == null) return {};
    final maps = await _database!.query('downloaded_tracks');
    return {for (var map in maps) map['id'] as String: map['file_path'] as String};
  }

  @override
  Future<void> addTrack(Track track, String filePath) async {
    if (_database == null) return;
    await _database!.insert(
      'downloaded_tracks',
      {
        'id': track.id,
        'title': track.title,
        'artist': track.artist,
        'file_path': filePath,
        'duration': track.duration,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeTrack(String trackId) async {
    if (_database == null) return;
    await _database!.delete('downloaded_tracks', where: 'id = ?', whereArgs: [trackId]);
  }

  @override
  Future<bool> isDownloaded(String trackId) async {
    if (_database == null) return false;
    final result = await _database!.query('downloaded_tracks', where: 'id = ?', whereArgs: [trackId]);
    return result.isNotEmpty;
  }

  @override
  Future<String?> getFilePath(String trackId) async {
    if (_database == null) return null;
    final result = await _database!.query('downloaded_tracks', where: 'id = ?', whereArgs: [trackId]);
    if (result.isNotEmpty) return result.first['file_path'] as String;
    return null;
  }

  @override
  Future<void> clear() async {
    if (_database == null) return;
    await _database!.delete('downloaded_tracks');
  }
}