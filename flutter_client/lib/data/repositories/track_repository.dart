import 'dart:io';
import 'package:dio/dio.dart';
import 'package:spotifree/data/services/offline_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotifree/domain/repositories/i_track_repository.dart';
import 'package:spotifree/data/services/tracks_service.dart';
import 'package:spotifree/models/track.dart';

class TrackRepository implements ITrackRepository {
  final TracksService _api;
  final OfflineStorage _storage;
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  TrackRepository({TracksService? api, OfflineStorage? storage})
      : _api = api ?? TracksService(),
        _storage = storage ?? OfflineStorage();

  @override
  Future<String> getStreamUrl(String trackId) async {
    return await _api.getPresignedStreamUrl(trackId);
  }

  @override
  Future<Map<String, dynamic>> getTaskStatus(int taskId) async {
    return await _api.getTaskStatus(taskId);
  }

  @override
  Future<String> downloadTrack(Track track, {Function(double)? onProgress}) async {
    final streamUrl = await getStreamUrl(track.id);
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${track.id}.mp3';
    final file = File(filePath);
    final cancelToken = CancelToken();
    _cancelTokens[track.id] = cancelToken;

    try {
      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress?.call(received / total);
          }
        },
        cancelToken: cancelToken,
      );
      await _storage.addDownloadedTrack(track, filePath);
      return filePath;
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        if (await file.exists()) await file.delete();
        throw Exception('Download cancelled');
      }
      rethrow;
    } finally {
      _cancelTokens.remove(track.id);
    }
  }

  @override
  Future<void> cancelDownload(String trackId) async {
    _cancelTokens[trackId]?.cancel();
    _cancelTokens.remove(trackId);
  }

  @override
  Future<bool> isTrackDownloaded(String trackId) async {
    return await _storage.isTrackDownloaded(trackId);
  }

  @override
  Future<String?> getDownloadedFilePath(String trackId) async {
    final paths = await _storage.getDownloadedFilePaths();
    return paths[trackId];
  }

  @override
  Future<List<Track>> getDownloadedTracks() async {
    return await _storage.getDownloadedTracks();
  }

  @override
  Future<void> removeDownloadedTrack(String trackId) async {
    final path = await getDownloadedFilePath(trackId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await _storage.removeDownloadedTrack(trackId);
  }
}