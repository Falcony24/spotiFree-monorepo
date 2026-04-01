import 'package:frontend/models/track.dart';
import 'package:frontend/services/download_storage.dart';

class MemoryDownloadStorage implements DownloadStorage {
  final Map<String, Track> _tracks = {};
  final Map<String, String> _filePaths = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<Track>> loadTracks() async {
    return _tracks.values.toList();
  }

  @override
  Future<Map<String, String>> loadFilePaths() async {
    return Map.from(_filePaths);
  }

  @override
  Future<void> addTrack(Track track, String filePath) async {
    _tracks[track.id] = track;
    _filePaths[track.id] = filePath;
  }

  @override
  Future<void> removeTrack(String trackId) async {
    _tracks.remove(trackId);
    _filePaths.remove(trackId);
  }

  @override
  Future<bool> isDownloaded(String trackId) async {
    return _tracks.containsKey(trackId);
  }

  @override
  Future<String?> getFilePath(String trackId) async {
    return _filePaths[trackId];
  }

  @override
  Future<void> clear() async {
    _tracks.clear();
    _filePaths.clear();
  }
}