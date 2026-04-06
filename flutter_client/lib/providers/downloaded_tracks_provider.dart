import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/offline_storage.dart';

class DownloadedTracksProvider extends ChangeNotifier {
  final UnifiedOfflineStorage _storage = UnifiedOfflineStorage();
  List<Track> _downloadedTracks = [];
  Map<String, String> _filePaths = {};
  bool _isLoading = false;

  List<Track> get downloadedTracks => _downloadedTracks;
  bool get isLoading => _isLoading;

  DownloadedTracksProvider() {
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

  bool isDownloaded(String trackId) => _filePaths.containsKey(trackId);
  String? getFilePath(String trackId) => _filePaths[trackId];

  Future<void> addDownloadedTrack(Track track, String filePath) async {
    await _storage.addDownloadedTrack(track, filePath);
    _downloadedTracks.add(track);
    _filePaths[track.id] = filePath;
    notifyListeners();
  }

  Future<void> removeDownloadedTrack(String trackId) async {
    await _storage.removeDownloadedTrack(trackId);
    _downloadedTracks.removeWhere((t) => t.id == trackId);
    _filePaths.remove(trackId);
    notifyListeners();
  }

  Future<void> clearDownloads() async {
    await _storage.clearAll(); 
    _downloadedTracks.clear();
    _filePaths.clear();
    notifyListeners();
  }
}