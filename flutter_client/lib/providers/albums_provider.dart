import 'package:flutter/material.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/providers/mode_provider.dart';

class AlbumsProvider extends ChangeNotifier {
  List<Album> _albums = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentLimit = 20;
  int _currentOffset = 0;
  bool _isLoadingMore = false;
  ModeProvider? _modeProvider;

  List<Album> get albums => _albums;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchAlbums({bool refresh = false}) async {
    if (_modeProvider?.isOfflineMode == true) {
      if (_albums.isEmpty && refresh) {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    if (refresh) {
      _albums.clear();
      _currentOffset = 0;
      _hasMore = true;
      _isLoading = true;
      _isLoadingMore = false;
      notifyListeners();
    } else if (_isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();
    try {
      final result = await ApiService().getAlbums(
        limit: _currentLimit,
        offset: _currentOffset,
      );
      final List<Album> newAlbums = (result['data'] as List)
          .map((item) => Album.fromJson(item))
          .toList();
      _albums.addAll(newAlbums);
      _currentOffset = _albums.length;
      _hasMore = _albums.length < result['total'];
    } catch (e) {
      debugPrint('Error fetching albums: $e');
      _albums = [];
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void reset() {
    _albums.clear();
    _isLoading = false;
    _hasMore = true;
    _currentOffset = 0;
    _isLoadingMore = false;
    notifyListeners();
  }
}