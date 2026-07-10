import 'package:spotifree/domain/repositories/i_album_repository.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/utils/constants.dart';

class GetAlbumMetadataUseCase {
  final IAlbumRepository repository;
  final ModeProvider modeProvider;
  
  GetAlbumMetadataUseCase(this.repository, this.modeProvider);

  Future<Album> execute(String albumId) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      return await repository.getAlbum(albumId, source: source);
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        return await repository.getAlbum(albumId, source: DataSource.local);
      }
      rethrow;
    }
  }
}