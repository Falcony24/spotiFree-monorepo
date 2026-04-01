import 'package:flutter/material.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/services/api_service.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _error;
  int _total = 0;
  int _currentLimit = 20;
  int _currentOffset = 0;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _playlists.length < _total;

  final ApiService _api = ApiService();

  Future<void> fetchPlaylists({
    int limit = 20,
    int offset = 0,
    bool refresh = false,
  }) async {
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(int playlistId) async {
    try {
      await _api.deletePlaylist(playlistId);
      _playlists.removeWhere((p) => p.id == playlistId);
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