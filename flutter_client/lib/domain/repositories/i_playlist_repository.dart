import 'package:frontend/models/playlist.dart';
import 'package:frontend/constants.dart';

abstract class IPlaylistRepository {
  Future<List<Playlist>> getPlaylists({required DataSource source, int limit = 20, int offset = 0, bool forceRefresh = false});
  Future<Playlist> createPlaylist(String name, {String? description, bool isPublic = false});
  Future<void> deletePlaylist(String playlistId);
  Future<Map<String, dynamic>> getPlaylistDetail(String playlistId, {required DataSource source});
  Future<void> addTrackToPlaylist(String playlistId, String trackMbid);
  Future<void> removeTrackFromPlaylist(String playlistId, String trackMbid);
}