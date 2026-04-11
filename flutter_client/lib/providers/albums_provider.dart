import 'package:flutter/material.dart';
import 'package:frontend/domain/usecases/get_albums_use_case.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/models/album.dart';

class AlbumsProvider extends ChangeNotifier {
  final GetAlbumsUseCase getAlbumsUseCase;
  final ModeProvider modeProvider;

  List<Album> _albums = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentLimit = 20;
  int _currentOffset = 0;
  bool _isLoadingMore = false;

  List<Album> get albums => _albums;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  AlbumsProvider({
    required this.getAlbumsUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {
    fetchAlbums(refresh: true);
  }

  Future<void> fetchAlbums({bool refresh = false}) async {
    if (refresh) {
      _albums.clear();
      _currentOffset = 0;
      _hasMore = true;
      _isLoading = true;
      notifyListeners();
    } else if (_isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newAlbums = await getAlbumsUseCase.execute(
        limit: _currentLimit,
        offset: _currentOffset,
        refresh: refresh,
      );
      _albums.addAll(newAlbums);
      _currentOffset = _albums.length;
      _hasMore = newAlbums.length == _currentLimit;
    } catch (e) {
      debugPrint('Error fetching albums: $e');
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

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}