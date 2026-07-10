import 'package:spotifree/models/track.dart';

abstract class ITrackRepository {
  Future<String> getStreamUrl(String trackId);
  Future<Map<String, dynamic>> getTaskStatus(int taskId);
  Future<String> downloadTrack(Track track, {Function(double)? onProgress});
  Future<void> cancelDownload(String trackId);
  Future<bool> isTrackDownloaded(String trackId);
  Future<String?> getDownloadedFilePath(String trackId);
  Future<List<Track>> getDownloadedTracks();
  Future<void> removeDownloadedTrack(String trackId);
}