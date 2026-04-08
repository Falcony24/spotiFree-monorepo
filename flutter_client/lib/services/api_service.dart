import 'dart:convert';
import 'package:frontend/models/artist.dart';
import 'package:frontend/services/AuthenticatedHttpClient.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/models/album.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/models/track.dart';

class PendingException implements Exception {
  final String message;
  final int taskId;
  PendingException(this.message, this.taskId);
}

class ApiService {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  Future<http.StreamedResponse> getAudioStream(String trackMbid) async {
    final token = await AuthService().getAccessToken();  
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final request = http.Request('GET', Uri.parse('$baseUrl/tracks/$trackMbid/audio'));
    request.headers.addAll(headers);
    final response = await request.send();

    if (response.statusCode == 200) {
      return response;
    } else if (response.statusCode == 202) {
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);
      throw PendingException('Track is being processed', data['taskId']);
    } else {
      throw Exception('Failed to get audio: ${response.statusCode}');
    }
  }

  Future<String> getPresignedStreamUrl(String trackMbid) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/tracks/$trackMbid/stream'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final url = data['streamUrl'];
      if (url == null) throw Exception('No stream URL in response');
      return url;
    } else if (response.statusCode == 202) {
      final data = jsonDecode(response.body);
      final taskId = data['taskId'];
      throw PendingException('Track is being processed', taskId);
    } else {
      throw Exception('Failed to get stream URL: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getTaskStatus(int taskId) async {
    final response = await _http.get(
      Uri.parse('$baseUrl/tracks/tasks/$taskId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get task status');
    }
  }

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

  Future<void> deletePlaylist(int playlistId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/playlists/$playlistId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to delete playlist');
    }
  }

  Future<Map<String, dynamic>> getPlaylistDetail(int playlistId) async {
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

  Future<void> addTrackToPlaylist(int playlistId, String trackMbid) async {
    final response = await _http.post(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks'),
      body: jsonEncode({'track_mbid': trackMbid}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add track to playlist');
    }
  }

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

  Future<Map<String, dynamic>> getArtistAlbums(String artistMbid, {int limit = 20, int offset = 0}) async {
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

  Future<Map<String, dynamic>> getArtistTracks(String artistMbid, {int limit = 20, int offset = 0}) async {
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
          'track': Track.fromJson(trackJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to fetch liked tracks');
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
          'album': Album.fromJson(albumJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to fetch liked albums');
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
          'artist': Artist.fromJson(artistJson),
        };
      }).whereType<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to fetch liked artists');
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

  Future<void> unlikeTrack(int favoriteId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/favorites/$favoriteId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike track');
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

  Future<void> unlikeAlbumById(int favoriteId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/favorites/$favoriteId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike album');
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

  Future<void> unlikeArtist(int favoriteId) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/favorites/$favoriteId'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to unlike artist');
    }
  }

  Future<Map<String, dynamic>> search(String query, {String? type, int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
      'q': query,
      'type': ?type,
      'limit': limit.toString(),
      'offset': offset.toString(),
    });
    final response = await _http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final artistsData = data['artists'] ?? {'data': [], 'total': 0};
      final albumsData = data['albums'] ?? {'data': [], 'total': 0};
      final tracksData = data['tracks'] ?? {'data': [], 'total': 0};
      return {
        'artists': {
          'data': (artistsData['data'] as List)
              .map((json) => Artist.fromJson(json))
              .toList(),
          'total': artistsData['total'],
        },
        'albums': {
          'data': (albumsData['data'] as List)
              .map((json) => Album.fromJson(json))
              .toList(),
          'total': albumsData['total'],
        },
        'tracks': {
          'data': (tracksData['data'] as List)
              .map((json) => Track.fromJson(json))
              .toList(),
          'total': tracksData['total'],
        },
      };
    } else {
      throw Exception('Błąd wyszukiwania');
    }
  }

  Future<void> removeTrackFromPlaylist(int playlistId, String trackMbid) async {
    final response = await _http.delete(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks/$trackMbid'),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to remove track from playlist');
    }
  }

  Future<void> reorderPlaylistTracks(int playlistId, List<Map<String, dynamic>> newOrder) async {
    final response = await _http.put(
      Uri.parse('$baseUrl/playlists/$playlistId/tracks/reorder'),
      body: jsonEncode(newOrder),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reorder tracks');
    }
  }

  Future<Playlist> updatePlaylist(int playlistId, {String? name, String? description, bool? isPublic}) async {
    final response = await _http.put(
      Uri.parse('$baseUrl/playlists/$playlistId'),
      body: jsonEncode({
        'name': ?name,
        'description': ?description,
        'is_public': ?isPublic,
      }),
    );
    if (response.statusCode == 200) {
      return Playlist.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update playlist');
    }
  }
}