import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_storage.dart';

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
  final UnifiedOfflineStorage _storage = UnifiedOfflineStorage();

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
      await _storage.insertPlaylist(playlist);
    }
  }

  Future<void> _loadFromOffline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _playlists = await _storage.getAllPlaylists();
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
    final isOffline = _modeProvider?.isOfflineMode == true;
    try {
      if (!isOffline) {
        await _api.deletePlaylist(playlistId);
        await _storage.permanentlyDeletePlaylist(playlistId);
      } else {
        if (playlistId > 0) {
          await _storage.markPlaylistAsDeleted(playlistId);
        } else {
          await _storage.permanentlyDeletePlaylist(playlistId);
        }
      }
      _playlists.removeWhere((p) => p.id == playlistId);
      notifyListeners();
    } catch (e) {
      debugPrint('Błąd usuwania playlisty: $e');
    }
  }

  Future<Playlist?> createPlaylist(String name, {String? description, bool isPublic = false}) async {
    final isOffline = _modeProvider?.isOfflineMode == true;
    try {
      if (!isOffline) {
        final playlist = await _api.createPlaylist(name, description: description, isPublic: isPublic);
        await _storage.insertPlaylist(playlist);
        _playlists.add(playlist);
        notifyListeners();
        return playlist;
      } else {
        final tempId = -DateTime.now().millisecondsSinceEpoch;
        final playlist = Playlist(
          id: tempId,
          name: name,
          description: description,
          isPublic: isPublic,
          userId: 0,
        );
        await _storage.insertPlaylist(playlist);
        await _storage.addToSyncQueue('playlist', 'create', tempId.toString(),
            payload: jsonEncode({'name': name, 'description': description, 'is_public': isPublic}));
        _playlists.add(playlist);
        notifyListeners();
        return playlist;
      }
    } catch (e) {
      debugPrint('Błąd tworzenia playlisty: $e');
      return null;
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