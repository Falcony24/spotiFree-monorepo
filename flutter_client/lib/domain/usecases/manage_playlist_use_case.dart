import 'package:spotifree/domain/repositories/i_playlist_repository.dart';
import 'package:spotifree/models/playlist.dart';
import 'package:spotifree/providers/mode_provider.dart';

class ManagePlaylistUseCase {
  final IPlaylistRepository repository;
  final ModeProvider modeProvider;

  ManagePlaylistUseCase({required this.repository, required this.modeProvider});

  Future<Playlist> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    return await repository.createPlaylist(name, description: description, isPublic: isPublic);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await repository.deletePlaylist(playlistId);
  }

  Future<void> addTrackToPlaylist(String playlistId, String trackMbid) async {
    await repository.addTrackToPlaylist(playlistId, trackMbid);
  }

  Future<void> removeTrackFromPlaylist(String playlistId, String trackMbid) async {
    await repository.removeTrackFromPlaylist(playlistId, trackMbid);
  }
}