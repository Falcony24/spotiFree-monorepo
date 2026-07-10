import 'dart:io';
import 'package:spotifree/data/repositories/track_repository.dart';

class DeleteDownloadedTrackUseCase {
  final TrackRepository _repository;

  DeleteDownloadedTrackUseCase({TrackRepository? repository})
      : _repository = repository ?? TrackRepository();

  Future<void> execute(String trackId, String filePath) async {
    final file = File(filePath);
    if (await file.exists()) await file.delete();
    await _repository.removeDownloadedTrack(trackId);
  }
}