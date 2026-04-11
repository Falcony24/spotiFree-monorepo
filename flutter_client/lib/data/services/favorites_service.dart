import 'dart:convert';
import 'package:frontend/data/services/authenticated_http_client.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/artist.dart';

class FavoritesService {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  Future<List<Map<String, dynamic>>> getLikedTracks() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/favorites?type=track'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        final trackJson = json['track'];
        if (trackJson == null) return null;
        return {
          'id': json['id'],
          'entity': Track.fromJson(trackJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to fetch liked tracks');
    }
  }

  Future<Map<String, dynamic>> likeTrack(String trackMbid) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/favorites'),
      body: jsonEncode({'item_type': 'track', 'item_mbid': trackMbid}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to like track');
    }
  }

  Future<void> unlikeTrack(String favoriteId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/favorites/$favoriteId?type=track'),   
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike track');
    }
  }

  Future<List<Map<String, dynamic>>> getLikedAlbums() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/favorites?type=album'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        final albumJson = json['album'];
        if (albumJson == null) return null;
        return {
          'id': json['id'].toString(),
          'entity': Album.fromJson(albumJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to fetch liked albums');
    }
  }

  Future<Map<String, dynamic>> likeAlbum(String albumMbid) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/favorites'),
      body: jsonEncode({'item_type': 'album', 'item_mbid': albumMbid}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to like album');
    }
  }

  Future<void> unlikeAlbum(String favoriteId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/favorites/$favoriteId?type=album'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike album');
    }
  }

  Future<List<Map<String, dynamic>>> getLikedArtists() async {
    final response = await _http.get(
      Uri.parse('$baseUrl/favorites?type=artist'),
    );
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) {
        final artistJson = json['artist'];
        if (artistJson == null) return null;
        return {
          'id': json['id'],
          'entity': Artist.fromJson(artistJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to fetch liked artists');
    }
  }

  Future<Map<String, dynamic>> likeArtist(String artistMbid) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/favorites'),
      body: jsonEncode({'item_type': 'artist', 'item_mbid': artistMbid}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to like artist');
    }
  }

  Future<void> unlikeArtist(String favoriteId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/favorites/$favoriteId?type=artist'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike artist');
    }
  }
}