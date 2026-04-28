import 'package:frontend/domain/repositories/i_artist_repository.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/providers/mode_provider.dart';

class GetArtistAlbumsUseCase {
  final IArtistRepository repository;
  final ModeProvider modeProvider;

  GetArtistAlbumsUseCase({required this.repository, required this.modeProvider});

  Future<List<Album>> execute(String artistId, {int limit = 20, int offset = 0}) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      return await repository.getArtistAlbums(artistId, source: source, limit: limit, offset: offset);
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        return await repository.getArtistAlbums(artistId, source: DataSource.local);
      }
      rethrow;
    }
  }
}