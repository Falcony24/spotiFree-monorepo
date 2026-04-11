import 'package:flutter/material.dart';
import 'package:frontend/domain/usecases/get_artist_tracks_use_case.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/models/track.dart';

class ArtistTracksProvider extends ChangeNotifier {
  final GetArtistTracksUseCase getArtistTracksUseCase;
  final ModeProvider modeProvider;

  List<Track> _tracks = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  bool _hasLoadedOnce = false;

  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  ArtistTracksProvider({
    required this.getArtistTracksUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {}

  Future<void> loadInitial(String artistId) async {
    if (_hasLoadedOnce) return;
    _hasLoadedOnce = true;
    await _loadTracks(artistId, reset: true);
  }

  Future<void> loadMore(String artistId) async {
    if (_isLoading || !_hasMore) return;
    await _loadTracks(artistId, reset: false);
  }

  Future<void> _loadTracks(String artistId, {required bool reset}) async {
    if (reset) {
      _tracks.clear();
      _offset = 0;
      _hasMore = true;
      _error = null;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final tracks = await getArtistTracksUseCase.execute(artistId, limit: 20, offset: _offset);
      _tracks.addAll(tracks);
      _offset += tracks.length;
      _hasMore = tracks.length == 20;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _tracks = [];
    _isLoading = false;
    _hasMore = true;
    _offset = 0;
    _error = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}