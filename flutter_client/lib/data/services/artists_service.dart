import 'dart:convert';
import 'package:spotifree/data/services/authenticated_http_client.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/utils/constants.dart' as constants;

class ArtistsService {
  final AuthenticatedHttpClient _http;
  final String baseUrl;

  ArtistsService({String? baseUrl, AuthenticatedHttpClient? httpClient})
      : baseUrl = baseUrl ?? constants.baseUrl,
        _http = httpClient ?? AuthenticatedHttpClient();

  Future<Map<String, dynamic>> getArtist(String artistMbid) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/artists/$artistMbid'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch artist');
    }
  }

  Future<Map<String, dynamic>> getArtistAlbums(
    String artistMbid, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/artists/$artistMbid/albums?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      final List<Album> albums = list.map((json) => Album.fromJson(json)).toList();
      return {
        'data': albums,
        'total': data['total'],
        'limit': data['limit'],
        'offset': data['offset'],
      };
    } else {
      throw Exception('Failed to fetch artist albums');
    }
  }

  Future<Map<String, dynamic>> getArtistTracks(
    String artistMbid, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/artists/$artistMbid/tracks?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      final List<Track> tracks = list.map((json) => Track.fromJson(json)).toList();
      return {
        'data': tracks,
        'total': data['total'],
        'limit': data['limit'],
        'offset': data['offset'],
      };
    } else {
      throw Exception('Failed to fetch artist tracks');
    }
  }
}