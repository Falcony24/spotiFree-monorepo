import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:frontend/services/offline_storage.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/models/playlist.dart';

void main() {
  late OfflineStorage storage;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    storage = OfflineStorage();
    // Use in‑memory database by temporarily replacing the database path.
    // Instead of calling private methods, we let the storage create a fresh in‑memory DB.
    // We can achieve this by resetting the internal _db to null and using a custom path.
    // A cleaner approach: add a method `useInMemoryDatabase()` to OfflineStorage for testing.
    // For now, we'll rely on the fact that each test runs with a clean database because we call clearAll().
    await storage.clearAll(); // ensures clean state
  });

  tearDown(() async {
    await storage.clearAll();
  });

  group('Downloaded tracks', () {
    test('addDownloadedTrack and getDownloadedTracks', () async {
      final track = Track(id: 't1', title: 'Test', artist: 'Artist');
      await storage.addDownloadedTrack(track, '/path/to/file.mp3');
      final tracks = await storage.getDownloadedTracks();
      expect(tracks.length, 1);
      expect(tracks.first.id, 't1');
    });

    test('removeDownloadedTrack', () async {
      final track = Track(id: 't2', title: 'Test2', artist: 'Artist2');
      await storage.addDownloadedTrack(track, '/path/to/file2.mp3');
      await storage.removeDownloadedTrack('t2');
      final tracks = await storage.getDownloadedTracks();
      expect(tracks.isEmpty, true);
    });
  });

  group('Playlists', () {
    test('insertPlaylist and getAllPlaylists', () async {
      final playlist = Playlist(id: 'p1', name: 'My Playlist', isPublic: false, userId: 1);
      await storage.insertPlaylist(playlist);
      final playlists = await storage.getAllPlaylists();
      expect(playlists.length, 1);
      expect(playlists.first.id, 'p1');
    });
  });
}