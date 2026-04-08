import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/api_service.dart';

class ArtistTracksProvider extends ChangeNotifier {
  List<Track> _tracks = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  int _total = 0;
  String? _error;
  bool _hasLoadedOnce = false;

  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

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
      final result = await ApiService().getArtistTracks(
        artistId,
        limit: 20,
        offset: _offset,
      );
      final newTracks = List<Track>.from(result['data']);
      _tracks.addAll(newTracks);
      _offset += newTracks.length;
      _total = result['total'];
      _hasMore = _tracks.length < _total;
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
    _total = 0;
    _error = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}