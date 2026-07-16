import 'dart:convert';
import 'package:spotifree/data/services/authenticated_http_client.dart';
import 'package:spotifree/data/services/api_cache.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/utils/constants.dart' as constants;

class FavoritesService {
  final AuthenticatedHttpClient _http ;
  final String _baseUrl;
  final ApiCache _cache = ApiCache();

  FavoritesService({String? baseUrl, AuthenticatedHttpClient? http})
    : _baseUrl = baseUrl ?? constants.baseUrl,
    _http = http ?? AuthenticatedHttpClient();

  Future<List<Map<String, dynamic>>> getLikedTracks() async {
    const cacheKey = 'favorites_tracks';
    final cached = _cache.get<List>(cacheKey);
    if (cached != null) {
      return cached.cast<Map<String, dynamic>>();
    }

    final response = await _http.get(
      Uri.parse('$_baseUrl/favorites?type=track'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final items = data.map((json) {
        final trackJson = json['track'];
        if (trackJson == null) return null;
        return {
          'id': json['id'],
          'entity': Track.fromJson(trackJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
      _cache.set(cacheKey, items, ttl: const Duration(seconds: 30));
      return items;
    } else {
      throw Exception('Failed to fetch liked tracks');
    }
  }

  Future<Map<String, dynamic>> likeTrack(String trackMbid) async {
    _cache.invalidate(prefix: 'favorites_');
    final response = await _http.post(
      Uri.parse('$_baseUrl/favorites'),
      body: jsonEncode({'item_type': 'track', 'item_mbid': trackMbid}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to like track');
    }
  }

  Future<void> unlikeTrack(String favoriteId) async {
    _cache.invalidate(prefix: 'favorites_');
    final response = await _http.delete(
      Uri.parse('$_baseUrl/favorites/$favoriteId?type=track'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike track');
    }
  }

  Future<List<Map<String, dynamic>>> getLikedAlbums() async {
    const cacheKey = 'favorites_albums';
    final cached = _cache.get<List>(cacheKey);
    if (cached != null) {
      return cached.cast<Map<String, dynamic>>();
    }

    final response = await _http.get(
      Uri.parse('$_baseUrl/favorites?type=album'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final items = data.map((json) {
        final albumJson = json['album'];
        if (albumJson == null) return null;
        return {
          'id': json['id'].toString(),
          'entity': Album.fromJson(albumJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
      _cache.set(cacheKey, items, ttl: const Duration(seconds: 30));
      return items;
    } else {
      throw Exception('Failed to fetch liked albums');
    }
  }

  Future<Map<String, dynamic>> likeAlbum(String albumMbid) async {
    _cache.invalidate(prefix: 'favorites_');
    final response = await _http.post(
      Uri.parse('$_baseUrl/favorites'),
      body: jsonEncode({'item_type': 'album', 'item_mbid': albumMbid}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to like album');
    }
  }

  Future<void> unlikeAlbum(String favoriteId) async {
    _cache.invalidate(prefix: 'favorites_');
    final response = await _http.delete(
      Uri.parse('$_baseUrl/favorites/$favoriteId?type=album'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike album');
    }
  }

  Future<List<Map<String, dynamic>>> getLikedArtists() async {
    const cacheKey = 'favorites_artists';
    final cached = _cache.get<List>(cacheKey);
    if (cached != null) {
      return cached.cast<Map<String, dynamic>>();
    }

    final response = await _http.get(
      Uri.parse('$_baseUrl/favorites?type=artist'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final items = data.map((json) {
        final artistJson = json['artist'];
        if (artistJson == null) return null;
        return {
          'id': json['id'],
          'entity': Artist.fromJson(artistJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
      _cache.set(cacheKey, items, ttl: const Duration(seconds: 30));
      return items;
    } else {
      throw Exception('Failed to fetch liked artists');
    }
  }

  Future<Map<String, dynamic>> likeArtist(String artistMbid) async {
    _cache.invalidate(prefix: 'favorites_');
    final response = await _http.post(
      Uri.parse('$_baseUrl/favorites'),
      body: jsonEncode({'item_type': 'artist', 'item_mbid': artistMbid}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to like artist');
    }
  }

  Future<void> unlikeArtist(String favoriteId) async {
    _cache.invalidate(prefix: 'favorites_');
    final response = await _http.delete(
      Uri.parse('$_baseUrl/favorites/$favoriteId?type=artist'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike artist');
    }
  }
}