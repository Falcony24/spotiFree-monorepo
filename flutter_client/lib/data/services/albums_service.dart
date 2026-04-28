import 'dart:convert';
import 'package:frontend/data/services/authenticated_http_client.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/utils/constants.dart' as constants;

class AlbumsService {
  final AuthenticatedHttpClient _http;
  final String baseUrl;

  AlbumsService({String? baseUrl, AuthenticatedHttpClient? httpClient})
      : baseUrl = baseUrl ?? constants.baseUrl,
        _http = httpClient ?? AuthenticatedHttpClient();

  Future<Map<String, dynamic>> getAlbums({int limit = 20, int offset = 0}) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/albums?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch albums');
    }
  }

  Future<Map<String, dynamic>> getAlbum(String albumMbid) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/albums/$albumMbid'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch album');
    }
  }

  Future<List<Track>> getAlbumTracks(String albumMbid) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/albums/$albumMbid/tracks'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Track.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch album tracks');
    }
  }
}