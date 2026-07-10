import 'package:spotifree/data/services/auth_service.dart';
import 'package:http/http.dart' as http;

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);
}

class AuthenticatedHttpClient {
  final AuthService authService = AuthService();
  final http.Client _client = http.Client();

  Future<http.Response> get(Uri url) async {
    return _request(() async => _client.get(url, headers: await _getHeaders()));
  }

  Future<http.Response> post(Uri url, {Object? body}) async {
    return _request(() async => _client.post(url, headers: await _getHeaders(), body: body));
  }

  Future<http.Response> put(Uri url, {Object? body}) async {
    return _request(() async => _client.put(url, headers: await _getHeaders(), body: body));
  }

  Future<http.Response> patch(Uri url, {Object? body}) async {
    return _request(() async => _client.patch(url, headers: await _getHeaders(), body: body));
  }

  Future<http.Response> delete(Uri url) async {
    return _request(() async => _client.delete(url, headers: await _getHeaders()));
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _request(
    Future<http.Response> Function() request, {
    int retries = 1,
  }) async {
    var response = await request();
    if (response.statusCode == 401 && retries > 0) {
      final refreshed = await authService.refreshToken();
      if (refreshed) {
        return _request(request, retries: retries - 1);
      } else {
        await authService.logout();
        throw UnauthorizedException();
      }
    }
    return response;
  }

  void close() {
    _client.close();
  }
}