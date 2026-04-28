import 'package:frontend/data/services/offline_storage.dart';
import 'package:frontend/domain/repositories/i_album_repository.dart';
import 'package:frontend/data/services/albums_service.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/utils/constants.dart';

class AlbumRepository implements IAlbumRepository {
  final AlbumsService _api;
  final OfflineStorage _storage;

  AlbumRepository({AlbumsService? api, OfflineStorage? storage})
      : _api = api ?? AlbumsService(),
        _storage = storage ?? OfflineStorage();

  @override
  Future<List<Album>> getAlbums({
    required DataSource source,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    if (source == DataSource.remote) {
      final result = await _api.getAlbums(limit: limit, offset: offset);
      final List<Album> albums = (result['data'] as List)
          .map((item) => Album.fromJson(item))
          .toList();
      return albums;
    } else {
      return await _storage.getLikedAlbums();
    }
  }

  @override
  Future<Album> getAlbum(String albumId, {required DataSource source}) async {
    if (source == DataSource.remote) {
      final data = await _api.getAlbum(albumId);
      return Album.fromJson(data);
    } else {
      final albums = await _storage.getLikedAlbums();
      final album = albums.firstWhere((a) => a.id == albumId);
      return album;
    }
  }

  @override
  Future<List<Track>> getAlbumTracks(String albumId, {required DataSource source}) async {
    if (source == DataSource.remote) {
      final tracks = await _api.getAlbumTracks(albumId);
      if (await _storage.isAlbumLiked(albumId)) {
        await _storage.saveLikedAlbumTracks(albumId, tracks);
      }
      return tracks;
    } else {
      return await _storage.getLikedAlbumTracks(albumId);
    }
  }
}