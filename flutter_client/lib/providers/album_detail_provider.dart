import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/offline_storage.dart';

class AlbumDetailProvider extends ChangeNotifier {
  final String albumId;
  List<Track> _tracks = [];
  bool _isLoadingTracks = false;      
  bool _isRefreshing = false;         
  String? _errorTracks;
  ModeProvider? _modeProvider;
  final OfflineStorage _storage = OfflineStorage();

  List<Track> get tracks => _tracks;
  bool get isLoadingTracks => _isLoadingTracks;
  bool get isRefreshing => _isRefreshing;
  String? get errorTracks => _errorTracks;

  AlbumDetailProvider(this.albumId);

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchTracks({bool forceRefresh = false}) async {
    final isOffline = _modeProvider?.isOfflineMode == true;
    final isAlbumLiked = await _storage.isAlbumLiked(albumId);

    if (isOffline) {
      if (isAlbumLiked) {
        await _loadTracksFromOffline();
      } else {
        _errorTracks = 'Tryb offline – polub album, aby zapisać utwory.';
        _tracks = [];
        notifyListeners();
      }
      return;
    }

    final localTracks = await _storage.getLikedAlbumTracks(albumId);
    if (localTracks.isNotEmpty && !forceRefresh) {
      _tracks = localTracks;
      notifyListeners();
      debugPrint('Pobrano utwory albumu $albumId z lokalnej bazy podczas fetchTracks.');
      return;
    } else if (_tracks.isEmpty) {
      _isLoadingTracks = true;
      notifyListeners();
      debugPrint('Brak lokalnych utworów albumu $albumId, pokazuję loader.');
    }

    _isRefreshing = true;
    notifyListeners();

    try {
      final apiTracks = await ApiService().getAlbumTracks(albumId);
      _tracks = apiTracks;
      if (isAlbumLiked) {
        await _storage.saveLikedAlbumTracks(albumId, apiTracks);
      }
      _errorTracks = null;
    } catch (e) {
      if (_tracks.isEmpty) {
        _errorTracks = e.toString();
      }
    } finally {
      _isLoadingTracks = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _loadTracksFromOffline() async {
    _isLoadingTracks = true;
    _errorTracks = null;
    notifyListeners();
    try {
      _tracks = await _storage.getLikedAlbumTracks(albumId);
      if (_tracks.isEmpty) {
        _errorTracks = 'Brak zapisanych utworów dla tego albumu.';
      }
    } catch (e) {
      _errorTracks = e.toString();
      _tracks = [];
    } finally {
      _isLoadingTracks = false;
      notifyListeners();
    }
  }
}