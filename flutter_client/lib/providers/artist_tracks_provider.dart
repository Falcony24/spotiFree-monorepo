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

  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadMore(String artistId) async {
    if (_isLoading || !_hasMore) return;

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
    notifyListeners();
  }
}