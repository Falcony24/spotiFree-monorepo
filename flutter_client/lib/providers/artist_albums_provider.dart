import 'package:flutter/material.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/services/api_service.dart';

class ArtistAlbumsProvider extends ChangeNotifier {
  List<Album> _albums = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  int _total = 0;
  String? _error;

  List<Album> get albums => _albums;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadMore(String artistId) async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService().getArtistAlbums(
        artistId,
        limit: 20,
        offset: _offset,
      );
      final newAlbums = List<Album>.from(result['data']);
      _albums.addAll(newAlbums);
      _offset += newAlbums.length;
      _total = result['total'];
      _hasMore = _albums.length < _total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _albums = [];
    _isLoading = false;
    _hasMore = true;
    _offset = 0;
    _total = 0;
    _error = null;
  }
}