import 'dart:convert';
import 'package:frontend/data/services/authenticated_http_client.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/utils/constants.dart' as constants;

class PlaylistsService {
  final AuthenticatedHttpClient _http;
  final String _baseUrl;

  PlaylistsService({String? baseUrl, AuthenticatedHttpClient? http}) 
    : _baseUrl = baseUrl ?? constants.baseUrl, 
    _http = http ?? AuthenticatedHttpClient();

  Future<Map<String, dynamic>> getPlaylists({int limit = 20, int offset = 0}) async {
    final response = await _http.get(
      Uri.parse('$_baseUrl/playlists?limit=$limit&offset=$offset'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  Future<Playlist> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    final response = await _http.post(
      Uri.parse('$_baseUrl/playlists'),
      body: jsonEncode({'name': name, 'description': description, 'is_public': isPublic}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Playlist(
        id: data['id'],
        name: data['name'],
        isPublic: data['is_public'],
        userId: 0,
      );
    } else {
      throw Exception('Failed to create playlist');
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final response = await _http.delete(
      Uri.parse('$_baseUrl/playlists/$playlistId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete playlist');
    }
  }

  Future<Map<String, dynamic>> getPlaylistDetail(String playlistId) async {
    final response = await _http.get(
      Uri.parse('$_baseUrl/playlists/$playlistId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final playlist = Playlist.fromJson(data['playlist']);
      final List<Track> tracks = (data['tracks'] as List)
          .map((trackData) => Track.fromJson(trackData['track'] ?? trackData))
          .toList();
      return {'playlist': playlist, 'tracks': tracks};
    } else {
      throw Exception('Failed to load playlist details');
    }
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackMbid) async {
    final response = await _http.post(
      Uri.parse('$_baseUrl/playlists/$playlistId/tracks'),
      body: jsonEncode({'track_mbid': trackMbid}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add track to playlist');
    }
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackMbid) async {
    final response = await _http.delete(
      Uri.parse('$_baseUrl/playlists/$playlistId/tracks/$trackMbid'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to remove track from playlist');
    }
  }

  Future<void> reorderPlaylistTracks(String playlistId, List<Map<String, dynamic>> newOrder) async {
    final response = await _http.put(
      Uri.parse('$_baseUrl/playlists/$playlistId/tracks/reorder'),
      body: jsonEncode(newOrder),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder tracks');
    }
  }

  Future<Playlist> updatePlaylist(String playlistId, {String? name, String? description, bool? isPublic}) async {
    final response = await _http.put(
      Uri.parse('$_baseUrl/playlists/$playlistId'),
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