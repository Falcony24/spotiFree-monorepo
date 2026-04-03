import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/download_storage.dart';

import 'package:frontend/services/download_storage_web.dart'
    if (dart.library.io) 'package:frontend/services/download_storage_mobile.dart';

class DownloadedTracksProvider extends ChangeNotifier {
  late DownloadStorage _storage;
  List<Track> _downloadedTracks = [];
  Map<String, String> _filePaths = {};
  bool _isLoading = false;

  List<Track> get downloadedTracks => _downloadedTracks;
  bool get isLoading => _isLoading;

  DownloadedTracksProvider() {
    _storage = createDownloadStorage();
    _init();
  }

  Future<void> _init() async {
    await _storage.init();
    await loadDownloadedTracks();
  }

  Future<void> loadDownloadedTracks() async {
    _isLoading = true;
    notifyListeners();
    _downloadedTracks = await _storage.loadTracks();
    _filePaths = await _storage.loadFilePaths();
    _isLoading = false;
    notifyListeners();
  }

  bool isDownloaded(String trackId) => _filePaths.containsKey(trackId);
  String? getFilePath(String trackId) => _filePaths[trackId];

  Future<void> addDownloadedTrack(Track track, String filePath) async {
    await _storage.addTrack(track, filePath);
    _downloadedTracks.add(track);
    _filePaths[track.id] = filePath;
    notifyListeners();
  }

  Future<void> removeDownloadedTrack(String trackId) async {
    await _storage.removeTrack(trackId);
    _downloadedTracks.removeWhere((t) => t.id == trackId);
    _filePaths.remove(trackId);
    notifyListeners();
  }

  Future<void> clearDownloads() async {
    await _storage.clear();
    _downloadedTracks.clear();
    _filePaths.clear();
    notifyListeners();
  }
}