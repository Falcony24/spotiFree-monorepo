import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_playlist_storage.dart';

class PlaylistTracksProvider extends ChangeNotifier {
  List<Track> _tracks = [];
  bool _isLoading = false;
  String? _error;
  ModeProvider? _modeProvider;

  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();
  final OfflinePlaylistStorage _offlineStorage = OfflinePlaylistStorage();

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> loadTracks(int playlistId) async {
    if (_modeProvider?.isOfflineMode == true) {
      await _loadFromOffline(playlistId);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getPlaylistDetail(playlistId);
      _tracks = List<Track>.from(data['tracks']);
      await _offlineStorage.savePlaylistTracks(playlistId, _tracks);
    } catch (e) {
      _error = e.toString();
      _tracks = [];
      await _loadFromOffline(playlistId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromOffline(int playlistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tracks = await _offlineStorage.getPlaylistTracks(playlistId);
      if (_tracks.isEmpty) {
        _error = 'No offline data available for this playlist.';
      }
    } catch (e) {
      _error = e.toString();
      _tracks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}