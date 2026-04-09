import 'package:flutter/material.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_storage.dart';

class LikedAlbumsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;
  ModeProvider? _modeProvider;

  List<Map<String, dynamic>> get items => _items;
  List<Album> get albums => _items.map((item) => item['album'] as Album).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();
  final OfflineStorage _storage = OfflineStorage();

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchLikedAlbums() async {
    if (_modeProvider?.isOfflineMode == true) {
      await _loadFromOffline();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.getLikedAlbums();
      for (final item in _items) {
        await _storage.addLikedAlbum(item['id'], item['album']);
      }
    } catch (e) {
      _error = e.toString();
      await _loadFromOffline();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromOffline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final albums = await _storage.getLikedAlbums();
      _items = albums.map((album) => {
        'id': '', 
        'album': album,
      }).toList();
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
        if (_modeProvider?.isOfflineMode != true) {
          final favId = getFavoriteId(album.id);
          if (favId != null) {
            await _api.unlikeAlbumById(favId);
          }
        }
        await _storage.removeLikedAlbum(album.id);
        await _storage.removeLikedAlbumTracks(album.id);
        if (_modeProvider?.isOfflineMode == true) {
          await _storage.addToSyncQueue('liked_album', 'remove', album.id);
        }
        _items.removeWhere((item) => item['album'].id == album.id);
      } else {
        String newFavId;
        if (_modeProvider?.isOfflineMode != true) {
          final newFav = await _api.likeAlbum(album.id);
          newFavId = newFav['id'].toString();;
          await _storage.addLikedAlbum(newFavId, album);
          try {
            final tracks = await _api.getAlbumTracks(album.id);
            await _storage.saveLikedAlbumTracks(album.id, tracks);
          } catch (e) {
            debugPrint('Nie udało się pobrać utworów albumu: $e');
          }
          _items.add({
            'id': newFavId.toString(),
            'album': album,
          });
        } else {
          newFavId = 'local_${DateTime.now().millisecondsSinceEpoch}';
          await _storage.addLikedAlbum(newFavId, album);
          await _storage.addToSyncQueue('liked_album', 'add', album.id);
          _items.add({
            'id': newFavId.toString(),
            'album': album,
          });
        }
      }
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('Failed to like album')) {
      }
    }
  }
}