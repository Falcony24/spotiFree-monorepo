import 'package:frontend/data/services/offline_storage.dart';
import 'package:frontend/domain/repositories/i_artist_repository.dart';
import 'package:frontend/data/services/artists_service.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/constants.dart';

class ArtistRepository implements IArtistRepository {
  final ArtistsService _api;
  final OfflineStorage _storage;

  ArtistRepository({ArtistsService? api, OfflineStorage? storage})
      : _api = api ?? ArtistsService(),
        _storage = storage ?? OfflineStorage();

  @override
  Future<Artist> getArtist(String artistId, {required DataSource source}) async {
    if (source == DataSource.remote) {
      final data = await _api.getArtist(artistId);
      return Artist.fromJson(data);
    } else {
      final artists = await _storage.getLikedArtists();
      return artists.firstWhere((a) => a.id == artistId);
    }
  }

  @override
  Future<List<Album>> getArtistAlbums(String artistId, {required DataSource source, int limit = 20, int offset = 0}) async {
    if (source == DataSource.remote) {
      final result = await _api.getArtistAlbums(artistId, limit: limit, offset: offset);
      return result['data'] as List<Album>;
    } else {
      return [];
    }
  }

  @override
  Future<List<Track>> getArtistTracks(String artistId, {required DataSource source, int limit = 20, int offset = 0}) async {
    if (source == DataSource.remote) {
      final result = await _api.getArtistTracks(artistId, limit: limit, offset: offset);
      return result['data'] as List<Track>;
    } else {
      return [];
    }
  }
}