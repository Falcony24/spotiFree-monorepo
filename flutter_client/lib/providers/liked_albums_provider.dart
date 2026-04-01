import 'package:flutter/material.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/services/api_service.dart';

class LikedAlbumsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get items => _items;
  List<Album> get albums => _items.map((item) => item['album'] as Album).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();

  Future<void> fetchLikedAlbums() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.getLikedAlbums();
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isLiked(String albumId) {
    return _items.any((item) => item['album'].id == albumId);
  }

  String? getFavoriteId(String albumId) {
    for (final item in _items) {
      if (item['album'].id == albumId) {
        return item['id'] as String?;
      }
    }
    return null;
  }

  Future<void> toggleLike(Album album) async {
    final isCurrentlyLiked = isLiked(album.id);
    try {
      if (isCurrentlyLiked) {
        final favId = getFavoriteId(album.id);
        if (favId != null) {
          await _api.unlikeAlbumById(int.parse(favId));
          _items.removeWhere((item) => item['album'].id == album.id);
        }
      } else {
        final newFav = await _api.likeAlbum(album.id);
        debugPrint(newFav.toString());
        _items.add({
          'id': newFav['id'].toString(),
          'album': album,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Błąd podczas zmiany stanu polubienia: $e');
    }
  }
}