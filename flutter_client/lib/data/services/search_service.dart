import 'dart:convert';
import 'package:spotifree/data/services/authenticated_http_client.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/utils/constants.dart' as constants;

class SearchService {
  final AuthenticatedHttpClient _http;
  final String _baseUrl;

  SearchService({String? baseUrl, AuthenticatedHttpClient? http})
    : _baseUrl = baseUrl ?? constants.baseUrl,
      _http = http ?? AuthenticatedHttpClient();

  Future<Map<String, dynamic>> search(String query, {String? type, int limit = 20, int offset = 0}) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
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
}