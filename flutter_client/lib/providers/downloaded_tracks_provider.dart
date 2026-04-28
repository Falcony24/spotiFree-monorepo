import 'package:flutter/material.dart';
import 'package:frontend/data/services/tracks_service.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/data/services/offline_storage.dart';
import 'package:frontend/domain/usecases/download_track_use_case.dart';
import 'package:frontend/domain/usecases/delete_downloaded_track_use_case.dart';

class DownloadedTracksProvider extends ChangeNotifier {
  final OfflineStorage _storage = OfflineStorage();
  final DownloadTrackUseCase _downloadUseCase;
  final DeleteDownloadedTrackUseCase _deleteUseCase;

  List<Track> _downloadedTracks = [];
  Map<String, String> _filePaths = {};
  bool _isLoading = false;

  List<Track> get downloadedTracks => _downloadedTracks;
  bool get isLoading => _isLoading;
  bool isDownloaded(String trackId) => _filePaths.containsKey(trackId);
  String? getFilePath(String trackId) => _filePaths[trackId];

  DownloadedTracksProvider({
    required DownloadTrackUseCase downloadUseCase,
    required DeleteDownloadedTrackUseCase deleteUseCase,
  })  : _downloadUseCase = downloadUseCase,
        _deleteUseCase = deleteUseCase {
    _init();
  }

  Future<void> _init() async {
    await loadDownloadedTracks();
  }

  Future<void> loadDownloadedTracks() async {
    _isLoading = true;
    notifyListeners();
    _downloadedTracks = await _storage.getDownloadedTracks();
    _filePaths = await _storage.getDownloadedFilePaths();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> downloadTrack(Track track) async {
    try {
      final filePath = await _downloadUseCase.execute(track);
      await _storage.addDownloadedTrack(track, filePath);
      _downloadedTracks.add(track);
      _filePaths[track.id] = filePath;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

Future<void> downloadTracks(
  List<Track> tracks, {
  Function(int completed, int total)? onProgress,
}) async {  
  int completed = 0;
  int total = tracks.length;
  for (final track in tracks) {
    if (isDownloaded(track.id)) {
      completed++;
      onProgress?.call(completed, total);
      continue;
    }
    try {
      await downloadTrack(track);
    } on PendingException catch (e) {
      await _waitForTask(e.taskId, track);
      await downloadTrack(track);
    } catch (e) {
      debugPrint('Error downloading ${track.title}: $e');
    }
    completed++;
    onProgress?.call(completed, total);
  }
  await loadDownloadedTracks();
}

Future<void> _waitForTask(int taskId, Track track) async {
  int attempts = 0;
  const maxAttempts = 30;
  while (attempts < maxAttempts) {
    await Future.delayed(const Duration(seconds: 2));
    try {
      final status = await TracksService().getTaskStatus(taskId);
      if (status['status'] == 'completed') return;
      if (status['status'] == 'failed') throw Exception('Task failed');
    } catch (e) { /* ignoruj */ }
    attempts++;
  }
  throw Exception('Timeout waiting for track processing');
}
  
  Future<void> deleteTrack(Track track) async {
    final filePath = _filePaths[track.id];
    if (filePath != null) {
      await _deleteUseCase.execute(track.id, filePath);
      await _storage.removeDownloadedTrack(track.id);
      _downloadedTracks.removeWhere((t) => t.id == track.id);
      _filePaths.remove(track.id);
      notifyListeners();
    }
  }

  Future<void> clearDownloads() async {
    await _storage.clearAll();
    _downloadedTracks.clear();
    _filePaths.clear();
    notifyListeners();
  }
}