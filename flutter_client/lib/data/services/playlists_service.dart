import 'dart:convert';
import 'package:frontend/data/services/AuthenticatedHttpClient.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/models/track.dart';

class PlaylistsService {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  Future<Map<String, dynamic>> getPlaylists({int limit = 20, int offset = 0}) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/playlists?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      final List<Playlist> playlists = list.map((json) => Playlist.fromJson(json)).toList();
      return {
        'data': playlists,
        'total': data['total'],
        'limit': data['limit'],
        'offset': data['offset'],
      };
    } else {
      throw Exception('Nie udało się pobrać playlist');
    }
  }

  Future<Playlist> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/playlists'),
      body: jsonEncode({'name': name, 'description': description, 'is_public': isPublic}),
    );
    if (response.statusCode == 201) {
      return Playlist.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create playlist');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/playlists/$playlistId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete playlist');
    }
  }

  Future<Map<String, dynamic>> getPlaylistDetail(String playlistId) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/playlists/$playlistId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final playlist = Playlist.fromJson(data['playlist']);
      final List<Track> tracks = (data['tracks'] as List)
          .map((trackData) => Track.fromJson(trackData['track'] ?? trackData))
          .toList();
      return {'playlist': playlist, 'tracks': tracks};
    } else {
      throw Exception('Nie udało się pobrać playlisty');
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackMbid) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks'),
      body: jsonEncode({'track_mbid': trackMbid}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add track to playlist');
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackMbid) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks/$trackMbid'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to remove track from playlist');
    }
  }

  Future<void> reorderPlaylistTracks(String playlistId, List<Map<String, dynamic>> newOrder) async {
    final response = await _http.put(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks/reorder'),
      body: jsonEncode(newOrder),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder tracks');
    }
  }

  Future<Playlist> updatePlaylist(String playlistId, {String? name, String? description, bool? isPublic}) async {
    final response = await _http.put(
      Uri.parse('$baseUrl/playlists/$playlistId'),
      body: jsonEncode({
        'name': name,
        'description': description,
        'is_public': isPublic,
      }),
    );
    if (response.statusCode == 200) {
      return Playlist.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update playlist');
    }
  }
}