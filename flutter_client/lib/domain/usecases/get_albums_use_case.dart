import 'package:spotifree/utils/constants.dart';
import 'package:spotifree/domain/repositories/i_album_repository.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/providers/mode_provider.dart';

class GetAlbumsUseCase {
  final IAlbumRepository repository;
  final ModeProvider modeProvider;

  GetAlbumsUseCase({required this.repository, required this.modeProvider});

  Future<List<Album>> execute({int limit = 20, int offset = 0, bool refresh = false}) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      return await repository.getAlbums(
        source: source,
        limit: limit,
        offset: offset,
        forceRefresh: refresh,
      );
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        return await repository.getAlbums(source: DataSource.local);
      }
      rethrow;
    }
  }
}