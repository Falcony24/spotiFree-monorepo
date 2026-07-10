import 'package:spotifree/domain/repositories/i_artist_repository.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/utils/constants.dart';
import 'package:spotifree/providers/mode_provider.dart';

class GetArtistUseCase {
  final IArtistRepository repository;
  final ModeProvider modeProvider;

  GetArtistUseCase({required this.repository, required this.modeProvider});

  Future<Artist> execute(String artistId) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      return await repository.getArtist(artistId, source: source);
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        return await repository.getArtist(artistId, source: DataSource.local);
      }
      rethrow;
    }
  }
}