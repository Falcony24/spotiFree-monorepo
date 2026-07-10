import 'package:spotifree/utils/constants.dart';
import 'package:spotifree/domain/repositories/i_album_repository.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/mode_provider.dart';

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