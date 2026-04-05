import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/models/track.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final Dio _dio = Dio();
  Map<String, CancelToken> _cancelTokens = {};

  Future<String> downloadTrack(Track track, {Function(double progress)? onProgress}) async {
    final streamUrl = await ApiService().getPresignedStreamUrl(track.id);
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}\\${track.id}.mp3';
    final file = File(filePath);
    final cancelToken = CancelToken();
    _cancelTokens[track.id] = cancelToken;

    try {
      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress?.call(progress);
          }
        },
        cancelToken: cancelToken,
      );
      return filePath;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        if (file.existsSync()) await file.delete();
        throw Exception('Download cancelled');
      }
      rethrow;
    } finally {
      _cancelTokens.remove(track.id);
    }
  }

  void cancelDownload(String trackId) {
    final token = _cancelTokens[trackId];
    if (token != null) {
      token.cancel();
      _cancelTokens.remove(trackId);
    }
  }
}