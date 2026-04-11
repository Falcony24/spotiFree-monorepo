import 'dart:convert';
import 'package:frontend/data/services/AuthenticatedHttpClient.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/track.dart';

class SearchService {
  final AuthenticatedHttpClient _http = AuthenticatedHttpClient();
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  Future<Map<String, dynamic>> search(String query, {String? type, int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: {
      'q': query,
      if (type != null) 'type': type,
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
}