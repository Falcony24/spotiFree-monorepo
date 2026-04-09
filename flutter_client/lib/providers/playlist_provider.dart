import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/models/playlist.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_storage.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];
  bool _isLoading = false;      
  bool _isRefreshing = false;   
  String? _error;
  int _total = 0;
  int _currentLimit = 20;
  int _currentOffset = 0;
  ModeProvider? _modeProvider;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  int get total => _total;
  bool get hasMore => _playlists.length < _total;

  final ApiService _api = ApiService();
  final OfflineStorage _storage = OfflineStorage();

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchPlaylists({bool refresh = false}) async {
    final isOffline = _modeProvider?.isOfflineMode == true;

    if (isOffline) {
      await _loadFromOffline();
      return;
    }

    final cachedPlaylists = await _storage.getAllPlaylists();
    if (!refresh && cachedPlaylists.isNotEmpty) {
      _playlists = cachedPlaylists;
      _total = _playlists.length;
      notifyListeners();
    } else if (_playlists.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    _isRefreshing = true;
    notifyListeners();

    try {
      final result = await _api.getPlaylists(limit: _currentLimit, offset: 0);
      final freshPlaylists = List<Playlist>.from(result['data']);
      _total = result['total'];
      _currentLimit = result['limit'];
      _currentOffset = result['offset'];

      _playlists = freshPlaylists;
      _error = null;

      for (final playlist in freshPlaylists) {
        await _storage.insertPlaylist(playlist);
      }
    } catch (e) {
      if (_playlists.isEmpty) {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final isOffline = _modeProvider?.isOfflineMode == true;
    if (isOffline) return;
    if (_isLoading || _isRefreshing || !hasMore) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final result = await _api.getPlaylists(
        limit: _currentLimit,
        offset: _playlists.length,
      );
      final newPlaylists = List<Playlist>.from(result['data']);
      _playlists.addAll(newPlaylists);
      _total = result['total'];
      _currentOffset = result['offset'];

      for (final playlist in newPlaylists) {
        await _storage.insertPlaylist(playlist);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromOffline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _playlists = await _storage.getAllPlaylists();
      _total = _playlists.length;
      if (_playlists.isEmpty) {
        _error = 'Brak playlist w trybie offline. Aby je zapisać, połącz się z internetem.';
      }
    } catch (e) {
      _error = e.toString();
      _playlists = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchPlaylists(refresh: true);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final isOffline = _modeProvider?.isOfflineMode == true;
    try {
      if (!isOffline) {
        await _api.deletePlaylist(playlistId);
        await _storage.permanentlyDeletePlaylist(playlistId);
      } else {
        await _storage.markPlaylistAsDeleted(playlistId);
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
        final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        final playlist = Playlist(
          id: tempId,
          name: name,
          description: description,
          isPublic: isPublic,
          userId: 0,
        );
        await _storage.insertPlaylist(playlist);
        await _storage.addToSyncQueue('playlist', 'create', tempId,
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
}