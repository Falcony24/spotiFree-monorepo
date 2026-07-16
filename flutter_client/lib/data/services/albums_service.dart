import 'dart:convert';
import 'package:spotifree/data/services/authenticated_http_client.dart';
import 'package:spotifree/data/services/api_cache.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/utils/constants.dart' as constants;

class AlbumsService {
  final AuthenticatedHttpClient _http;
  final String baseUrl;
  final ApiCache _cache = ApiCache();

  AlbumsService({String? baseUrl, AuthenticatedHttpClient? httpClient})
      : baseUrl = baseUrl ?? constants.baseUrl,
        _http = httpClient ?? AuthenticatedHttpClient();

  Future<Map<String, dynamic>> getAlbums({int limit = 20, int offset = 0}) async {
    final cacheKey = 'albums_list_${limit}_$offset';
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final response = await _http.get(
      Uri.parse('$baseUrl/albums?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _cache.set(cacheKey, data, ttl: const Duration(seconds: 60));
      return data;
    } else {
      throw Exception('Failed to fetch albums');
    }
  }

  Future<Map<String, dynamic>> getAlbum(String albumMbid) async {
    final cacheKey = 'album_$albumMbid';
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final response = await _http.get(
      Uri.parse('$baseUrl/albums/$albumMbid'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _cache.set(cacheKey, data, ttl: const Duration(minutes: 5));
      return data;
    } else {
      throw Exception('Failed to fetch album');
    }
  }

  Future<List<Track>> getAlbumTracks(String albumMbid) async {
    final cacheKey = 'album_tracks_$albumMbid';
    final cached = _cache.get<List>(cacheKey);
    if (cached != null) return cached.cast<Track>();

    final response = await _http.get(
      Uri.parse('$baseUrl/albums/$albumMbid/tracks'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final tracks = data.map((json) => Track.fromJson(json)).toList();
      _cache.set(cacheKey, tracks, ttl: const Duration(minutes: 5));
      return tracks;
    } else {
      throw Exception('Failed to fetch album tracks');
    }
  }

  void invalidateAlbum(String albumMbid) {
    _cache.invalidate(prefix: 'album_$albumMbid');
  }

  void invalidateAlbumsList() {
    _cache.invalidate(prefix: 'albums_list_');
  }
}