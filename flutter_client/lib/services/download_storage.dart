import 'package:frontend/models/track.dart';

abstract class DownloadStorage {
  Future<void> init();
  Future<List<Track>> loadTracks();
  Future<Map<String, String>> loadFilePaths();
  Future<void> addTrack(Track track, String filePath);
  Future<void> removeTrack(String trackId);
  Future<bool> isDownloaded(String trackId);
  Future<String?> getFilePath(String trackId);
  Future<void> clear();
}