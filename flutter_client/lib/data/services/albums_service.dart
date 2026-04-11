import 'dart:convert';
import 'package:frontend/data/services/AuthenticatedHttpClient.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/track.dart';

class AlbumsService {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  Future<Map<String, dynamic>> getAlbums({int limit = 20, int offset = 0}) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/albums?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nie udało się pobrać albumów');
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
      throw Exception('Nie udało się pobrać utworów albumu');
    }
  }
}