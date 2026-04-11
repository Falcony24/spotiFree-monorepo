import 'package:flutter/material.dart';
import 'package:frontend/domain/usecases/get_artist_albums_use_case.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/models/album.dart';

class ArtistAlbumsProvider extends ChangeNotifier {
  final GetArtistAlbumsUseCase getArtistAlbumsUseCase;
  final ModeProvider modeProvider;

  List<Album> _albums = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  bool _hasLoadedOnce = false;

  List<Album> get albums => _albums;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  ArtistAlbumsProvider({
    required this.getArtistAlbumsUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {}

  Future<void> loadInitial(String artistId) async {
    if (_hasLoadedOnce) return;
    _hasLoadedOnce = true;
    await _loadAlbums(artistId, reset: true);
  }

  Future<void> loadMore(String artistId) async {
    if (_isLoading || !_hasMore) return;
    await _loadAlbums(artistId, reset: false);
  }

  Future<void> _loadAlbums(String artistId, {required bool reset}) async {
    if (reset) {
      _albums.clear();
      _offset = 0;
      _hasMore = true;
      _error = null;
    }
    _isLoading = true;
    notifyListeners();

    try {
      final albums = await getArtistAlbumsUseCase.execute(artistId, limit: 20, offset: _offset);
      _albums.addAll(albums);
      _offset += albums.length;
      _hasMore = albums.length == 20;
      _error = null;
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