import 'package:frontend/domain/repositories/i_playlist_repository.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/constants.dart';
import 'package:frontend/providers/mode_provider.dart';

class GetPlaylistTracksUseCase {
  final IPlaylistRepository repository;
  final ModeProvider modeProvider;

  GetPlaylistTracksUseCase({required this.repository, required this.modeProvider});

  Future<List<Track>> execute(String playlistId) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      final detail = await repository.getPlaylistDetail(playlistId, source: source);
      return detail['tracks'] as List<Track>;
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        final detail = await repository.getPlaylistDetail(playlistId, source: DataSource.local);
        return detail['tracks'] as List<Track>;
      }
      rethrow;
    }
  }
}