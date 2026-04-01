import 'package:flutter/material.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/services/api_service.dart';

class LikedArtistsProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get items => _items;
  List<Artist> get artists => _items.map((item) => item['artist'] as Artist).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();

  Future<void> fetchLikedArtists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _api.getLikedArtists();
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
        final favId = getFavoriteId(artist.id);
        if (favId != null) {
          await _api.unlikeArtist(favId);
          _items.removeWhere((item) => item['artist'].id == artist.id);
        }
      } else {
        final newFav = await _api.likeArtist(artist.id);
        _items.add({
          'id': newFav['id'],
          'artist': artist,
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Błąd podczas zmiany stanu polubienia: $e');
    }
  }
}