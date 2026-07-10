import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotifree/utils/constants.dart' as constants;

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  final String _baseUrl;

  AuthService({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _baseUrl = baseUrl ?? constants.baseUrl;

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveTokens(data['accessToken'], data['refreshToken']);
      return data;
    } else {
      throw Exception('Błąd logowania: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String username, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveTokens(data['accessToken'], data['refreshToken']);
      return data;
    } else {
      throw Exception('Błąd rejestracji: ${response.body}');
    }
  }

  Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveTokens(data['accessToken'], data['refreshToken']);
        return true;
      } else {
        await clearTokens();
        return false;
      }
    } catch (e) {
      await clearTokens();
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken != null) {
      try {
        await _httpClient.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
      } catch (_) {}
    }
    await clearTokens();
  }
}