import 'package:frontend/domain/repositories/i_artist_repository.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/mode_provider.dart';

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