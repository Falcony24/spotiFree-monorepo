import 'package:frontend/utils/constants.dart';
import 'package:frontend/data/services/offline_storage.dart';
import 'package:frontend/data/services/favorites_service.dart';
import 'package:frontend/domain/repositories/i_favorites_repository.dart';
import 'package:frontend/models/track.dart';

class FavoritesRepository implements IFavoritesRepository {
  final FavoritesService _api;
  final OfflineStorage _storage;

  FavoritesRepository({FavoritesService? api, OfflineStorage? storage})
      : _api = api ?? FavoritesService(),
        _storage = storage ?? OfflineStorage();

  @override
  Future<List<Map<String, dynamic>>> getLikedTracks({
    required DataSource source,
    bool forceRefresh = false,
  }) async {
    if (source == DataSource.remote) {
      final items = await _api.getLikedTracks();
      for (final item in items) {
        await _storage.addLikedTrack(item['id'], item['entity']);
      }
      return items;
    } else {
      return await _storage.getLikedTracks();
    }
  }

  @override
  Future<String> likeTrack(String trackMbid) async {
    final result = await _api.likeTrack(trackMbid);
    return result['id'].toString();

  }

  @override
  Future<void> unlikeTrack(String favoriteId) async {
    await _api.unlikeTrack(favoriteId);
    await _storage.removeLikedTrack(favoriteId);
  }

  @override
  Future<bool> isTrackLiked(String trackId) async {
    return await _storage.isTrackLiked(trackId);
  }

  @override
  Future<String?> getFavoriteIdForTrack(String trackId) async {
    return await _storage.getFavoriteIdForTrack(trackId);
  }

  @override
  Future<List<Map<String, dynamic>>> getLikedAlbums({
    required DataSource source,
    bool forceRefresh = false,
  }) async {
    if (source == DataSource.remote) {
      final items = await _api.getLikedAlbums();
      for (final item in items) {
        await _storage.addLikedAlbum(item['id'], item['entity']);
      }
      return items;
    } else {
      final albums = await _storage.getLikedAlbums();
      return albums.map((a) => {'id': '', 'entity': a}).toList();
    }
  }

  @override
  Future<String> likeAlbum(String albumMbid) async {
    final result = await _api.likeAlbum(albumMbid);
    return result['id'].toString();
  }

  @override
  Future<void> unlikeAlbum(String favoriteId) async {
    await _api.unlikeAlbum(favoriteId);
  }

  @override
  Future<bool> isAlbumLiked(String albumId) async {
    return await _storage.isAlbumLiked(albumId);
  }

  @override
  Future<String?> getFavoriteIdForAlbum(String albumId) async {
    return await _storage.getFavoriteIdForAlbum(albumId);
  }

  @override
  Future<void> saveLikedAlbumTracks(String albumId, List<Track> tracks) async {
    await _storage.saveLikedAlbumTracks(albumId, tracks);
  }

  @override
  Future<List<Track>> getLikedAlbumTracks(String albumId) async {
    return await _storage.getLikedAlbumTracks(albumId);
  }

  @override
  Future<List<Map<String, dynamic>>> getLikedArtists({
    required DataSource source,
    bool forceRefresh = false,
  }) async {
    if (source == DataSource.remote) {
      final items = await _api.getLikedArtists();
      for (final item in items) {
        await _storage.addLikedArtist(item['id'], item['entity']);
      }
      return items;
    } else {
      final artists = await _storage.getLikedArtists();
      return artists.map((a) => {'id': '', 'entity': a}).toList();
    }
  }

  @override
  Future<String> likeArtist(String artistMbid) async {
    final result = await _api.likeArtist(artistMbid);
    return result['id'].toString();
  }

  @override
  Future<void> unlikeArtist(String favoriteId) async {
    await _api.unlikeArtist(favoriteId);
  }

  @override
  Future<bool> isArtistLiked(String artistId) async {
    return await _storage.isArtistLiked(artistId);
  }

  @override
  Future<String?> getFavoriteIdForArtist(String artistId) async {
    return await _storage.getFavoriteIdForArtist(artistId);
  }
}