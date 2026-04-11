import 'package:flutter/material.dart';
import 'package:frontend/domain/usecases/get_playlists_use_case.dart';
import 'package:frontend/domain/usecases/manage_playlist_use_case.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/models/playlist.dart';

class PlaylistProvider extends ChangeNotifier {
  final GetPlaylistsUseCase getPlaylistsUseCase;
  final ManagePlaylistUseCase managePlaylistUseCase;
  final ModeProvider modeProvider;

  List<Playlist> _playlists = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  int _total = 0;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => false;

  PlaylistProvider({
    required this.getPlaylistsUseCase,
    required this.managePlaylistUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {
    fetchPlaylists(refresh: true);
  }

  Future<void> fetchPlaylists({bool refresh = false}) async {
    if (refresh) {
      _playlists.clear();
      _total = 0;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final freshPlaylists = await getPlaylistsUseCase.execute(refresh: refresh);
      _playlists = freshPlaylists;
      _total = _playlists.length;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchPlaylists(refresh: true);
  }

  Future<void> deletePlaylist(String playlistId) async {
    await managePlaylistUseCase.deletePlaylist(playlistId);
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
  }

  Future<Playlist?> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    try {
      final playlist = await managePlaylistUseCase.createPlaylist(name, description: description, isPublic: isPublic);
      _playlists.add(playlist);
      notifyListeners();
      return playlist;
    } catch (e) {
      debugPrint('Błąd tworzenia playlisty: $e');
      return null;
    }
  }

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}