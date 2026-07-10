import 'package:spotifree/data/repositories/track_repository.dart';
import 'package:spotifree/models/track.dart';

class DownloadTrackUseCase {
  final TrackRepository _repository;

  DownloadTrackUseCase({TrackRepository? repository})
      : _repository = repository ?? TrackRepository();

  Future<String> execute(Track track) async {
    return await _repository.downloadTrack(track);
  }
}