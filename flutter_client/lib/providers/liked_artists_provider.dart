import 'package:flutter/material.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_storage.dart';

class LikedArtistsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;
  ModeProvider? _modeProvider;

  List<Map<String, dynamic>> get items => _items;
  List<Artist> get artists => _items.map((item) => item['artist'] as Artist).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();
  final OfflineStorage _storage = OfflineStorage();

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchLikedArtists() async {
    if (_modeProvider?.isOfflineMode == true) {
      await _loadFromOffline();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.getLikedArtists();
      for (final item in _items) {
        await _storage.addLikedArtist(item['id'], item['artist']);
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
      final artists = await _storage.getLikedArtists();
      _items = artists.map((artist) => {
        'id': '',
        'artist': artist,
      }).toList();
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isLiked(String artistId) {
    return _items.any((item) => item['artist'].id == artistId);
  }

  int? getFavoriteId(String artistId) {
    for (final item in _items) {
      if (item['artist'].id == artistId) {
        return item['id'] as int?;
      }
    }
    return null;
  }

  Future<void> toggleLike(Artist artist) async {
    final isCurrentlyLiked = isLiked(artist.id);
    try {
      if (isCurrentlyLiked) {
        if (_modeProvider?.isOfflineMode != true) {
          final favId = getFavoriteId(artist.id);
          if (favId != null) await _api.unlikeArtist(favId);
        }
        await _storage.removeLikedArtist(artist.id);
        if (_modeProvider?.isOfflineMode == true) {
          await _storage.addToSyncQueue('liked_artist', 'remove', artist.id);
        }
        _items.removeWhere((item) => item['artist'].id == artist.id);
      } else {
        int newFavId;
        if (_modeProvider?.isOfflineMode != true) {
          final newFav = await _api.likeArtist(artist.id);
          newFavId = newFav['id'];
        } else {
          newFavId = -1;
          await _storage.addToSyncQueue('liked_artist', 'add', artist.id);
        }
        await _storage.addLikedArtist(newFavId, artist);
        _items.add({
          'id': newFavId,
          'artist': artist,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Błąd podczas zmiany stanu polubienia: $e');
    }
  }
}