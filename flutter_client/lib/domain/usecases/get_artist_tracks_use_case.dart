import 'package:frontend/domain/repositories/i_artist_repository.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/utils/constants.dart';
import 'package:frontend/providers/mode_provider.dart';

class GetArtistTracksUseCase {
  final IArtistRepository repository;
  final ModeProvider modeProvider;

  GetArtistTracksUseCase({required this.repository, required this.modeProvider});

  Future<List<Track>> execute(String artistId, {int limit = 20, int offset = 0}) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      return await repository.getArtistTracks(artistId, source: source, limit: limit, offset: offset);
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        return await repository.getArtistTracks(artistId, source: DataSource.local);
      }
      rethrow;
    }
  }
}
