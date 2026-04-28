import 'package:frontend/utils/constants.dart';
import 'package:frontend/domain/repositories/i_playlist_repository.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/providers/mode_provider.dart';

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