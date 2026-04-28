import 'package:frontend/utils/constants.dart';
import 'package:frontend/domain/repositories/i_album_repository.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/mode_provider.dart';

class GetAlbumTracksUseCase {
  final IAlbumRepository repository;
  final ModeProvider modeProvider;

  GetAlbumTracksUseCase({required this.repository, required this.modeProvider});

  Future<List<Track>> execute(String albumId, {bool forceRefresh = false}) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      return await repository.getAlbumTracks(albumId, source: source);
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        return await repository.getAlbumTracks(albumId, source: DataSource.local);
      }
      rethrow;
    }
  }
}