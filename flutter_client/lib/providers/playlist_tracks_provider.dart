import 'package:flutter/material.dart';
import 'package:spotifree/domain/usecases/get_playlist_tracks_use_case.dart';
import 'package:spotifree/providers/mode_provider.dart';
import 'package:spotifree/models/track.dart';

class PlaylistTracksProvider extends ChangeNotifier {
  final GetPlaylistTracksUseCase getPlaylistTracksUseCase;
  final ModeProvider modeProvider;

  List<Track> _tracks = [];
  bool _isLoading = false;
  String? _error;

  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PlaylistTracksProvider({
    required this.getPlaylistTracksUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {}

  Future<void> loadTracks(String playlistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tracks = await getPlaylistTracksUseCase.execute(playlistId);
    } catch (e) {
      _error = e.toString();
      _tracks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}