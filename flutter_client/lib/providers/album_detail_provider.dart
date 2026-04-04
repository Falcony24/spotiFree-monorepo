import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/mode_provider.dart';

class AlbumDetailProvider extends ChangeNotifier {
  final String albumId;
  List<Track> _tracks = [];
  bool _isLoadingTracks = false;
  String? _errorTracks;
  ModeProvider? _modeProvider;

  List<Track> get tracks => _tracks;
  bool get isLoadingTracks => _isLoadingTracks;
  String? get errorTracks => _errorTracks;

  AlbumDetailProvider(this.albumId);

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchTracks() async {
    // If offline mode is enabled, show error and do nothing
    if (_modeProvider?.isOfflineMode == true) {
      _errorTracks = 'Tryb offline – brak dostępu do utworów. Wyłącz tryb offline, aby pobrać utwory.';
      _tracks = [];
      _isLoadingTracks = false;
      notifyListeners();
      return;
    }

    _isLoadingTracks = true;
    _errorTracks = null;
    notifyListeners();
    try {
      _tracks = await ApiService().getAlbumTracks(albumId);
    } catch (e) {
      _errorTracks = e.toString();
      _tracks = [];
    } finally {
      _isLoadingTracks = false;
      notifyListeners();
    }
  }
}