import 'package:flutter/material.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_playlist_storage.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;
  int _currentLimit = 20;
  int _currentOffset = 0;
  ModeProvider? _modeProvider;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _playlists.length < _total;

  final ApiService _api = ApiService();
  final OfflinePlaylistStorage _offlineStorage = OfflinePlaylistStorage();

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchPlaylists({
    int limit = 20,
    int offset = 0,
    bool refresh = false,
  }) async {
    if (_modeProvider?.isOfflineMode == true) {
      await _loadFromOffline();
      return;
    }

    if (refresh) {
      _playlists.clear();
      _currentOffset = 0;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.getPlaylists(limit: limit, offset: offset);
      _total = result['total'];
      _currentLimit = result['limit'];
      _currentOffset = result['offset'];

      if (refresh) {
        _playlists = List<Playlist>.from(result['data']);
      } else {
        _playlists.addAll(result['data']);
      }

      await _saveToOffline();
    } catch (e) {
      _error = e.toString();
      if (_playlists.isEmpty) {
        await _loadFromOffline();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToOffline() async {
    for (final playlist in _playlists) {
      await _offlineStorage.insertPlaylist(playlist);
    }
  }

  Future<void> _loadFromOffline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _playlists = await _offlineStorage.getAllPlaylists();
      _total = _playlists.length;
    } catch (e) {
      _error = e.toString();
      _playlists = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      await _api.deletePlaylist(playlistId);
      _playlists.removeWhere((p) => p.id == playlistId);
      await _offlineStorage.deletePlaylist(playlistId);
      notifyListeners();
    } catch (e) {
      debugPrint('Błąd usuwania playlisty: $e');
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !hasMore) return;
    await fetchPlaylists(
      limit: _currentLimit,
      offset: _playlists.length,
      refresh: false,
    );
  }
}