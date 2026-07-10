import 'package:spotifree/utils/constants.dart';
import 'package:spotifree/domain/repositories/i_playlist_repository.dart';
import 'package:spotifree/models/playlist.dart';
import 'package:spotifree/providers/mode_provider.dart';

class GetPlaylistsUseCase {
  final IPlaylistRepository repository;
  final ModeProvider modeProvider;

  GetPlaylistsUseCase({required this.repository, required this.modeProvider});

  Future<List<Playlist>> execute({bool refresh = false}) async {
    final source = modeProvider.isOfflineMode ? DataSource.local : DataSource.remote;
    try {
      return await repository.getPlaylists(source: source, forceRefresh: refresh);
    } catch (e) {
      if (!modeProvider.isOfflineMode && source == DataSource.remote) {
        return await repository.getPlaylists(source: DataSource.local);
      }
      rethrow;
    }
  }
}