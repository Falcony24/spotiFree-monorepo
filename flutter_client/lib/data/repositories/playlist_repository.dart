import 'package:frontend/data/services/offline_storage.dart';
import 'package:frontend/domain/repositories/i_playlist_repository.dart';
import 'package:frontend/data/services/playlists_service.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/utils/constants.dart';

class PlaylistRepository implements IPlaylistRepository {
  final PlaylistsService _api;
  final OfflineStorage _storage;

  PlaylistRepository({PlaylistsService? api, OfflineStorage? storage})
      : _api = api ?? PlaylistsService(),
        _storage = storage ?? OfflineStorage();

  @override
  Future<List<Playlist>> getPlaylists({
    required DataSource source,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    if (source == DataSource.remote) {
      final result = await _api.getPlaylists(limit: limit, offset: offset);
      final playlists = result['data'].map<Playlist>((json) => Playlist(
        id: json['id'], 
        name: json['name'], 
        description: json['description'], 
        isPublic: json['is_public'], 
        userId: 0, 
        ownerName: json['owner_name'])
        ).toList();
      for (final p in playlists) {
        await _storage.insertPlaylist(p);
      }
      return playlists;
    } else {
      return await _storage.getAllPlaylists();
    }
  }

  @override
  Future<Playlist> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    final playlist = await _api.createPlaylist(name, description: description, isPublic: isPublic);
    await _storage.insertPlaylist(playlist);
    return playlist;
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _api.deletePlaylist(playlistId);
    await _storage.permanentlyDeletePlaylist(playlistId);
  }

  @override
  Future<Map<String, dynamic>> getPlaylistDetail(String playlistId, {required DataSource source}) async {
    if (source == DataSource.remote) {
      final detail = await _api.getPlaylistDetail(playlistId);
      await _storage.savePlaylistTracks(playlistId, detail['tracks']);
      return detail;
    } else {
      final tracks = await _storage.getPlaylistTracks(playlistId);
      final playlist = (await _storage.getAllPlaylists()).firstWhere((p) => p.id == playlistId);
      return {'playlist': playlist, 'tracks': tracks};
    }
  }

  @override
  Future<void> addTrackToPlaylist(String playlistId, String trackMbid) async {
    await _api.addTrackToPlaylist(playlistId, trackMbid);
  }

  @override
  Future<void> removeTrackFromPlaylist(String playlistId, String trackMbid) async {
    await _api.removeTrackFromPlaylist(playlistId, trackMbid);
  }
}