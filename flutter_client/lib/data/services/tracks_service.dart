import 'dart:convert';
import 'package:frontend/data/services/AuthenticatedHttpClient.dart';
import 'package:frontend/data/services/auth_service.dart';
import 'package:http/http.dart' as http;

class PendingException implements Exception {
  final String message;
  final int taskId;
  PendingException(this.message, this.taskId);
}

class TracksService {
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
}