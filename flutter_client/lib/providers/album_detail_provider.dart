import 'package:flutter/material.dart';
import 'package:frontend/domain/usecases/get_album_tracks_use_case.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/models/track.dart';

class AlbumDetailProvider extends ChangeNotifier {
  final String albumId;
  final GetAlbumTracksUseCase getAlbumTracksUseCase;
  final ModeProvider modeProvider;

  List<Track> _tracks = [];
  bool _isLoadingTracks = false;
  bool _isRefreshing = false;
  String? _errorTracks;

  List<Track> get tracks => _tracks;
  bool get isLoadingTracks => _isLoadingTracks;
  bool get isRefreshing => _isRefreshing;
  String? get errorTracks => _errorTracks;

  AlbumDetailProvider({
    required this.albumId,
    required this.getAlbumTracksUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {
    fetchTracks(forceRefresh: true);
  }

  Future<void> fetchTracks({bool forceRefresh = false}) async {
    if (forceRefresh || _tracks.isEmpty) {
      _isLoadingTracks = true;
      _errorTracks = null;
      notifyListeners();
    } else {
      _isRefreshing = true;
      notifyListeners();
    }

    try {
      _tracks = await getAlbumTracksUseCase.execute(albumId, forceRefresh: forceRefresh);
    } catch (e) {
      _errorTracks = e.toString();
      if (_tracks.isEmpty) _tracks = [];
    } finally {
      _isLoadingTracks = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}