import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/api_service.dart';

class LikedTracksProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _likedItems = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get likedItems => _likedItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();

  Future<void> fetchLikedTracks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _likedItems = await _api.getLikedTracks();
    } catch (e) {
      _error = e.toString();
      _likedItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isLiked(String trackMbid) {
    return _likedItems.any((item) => item['track']?.id == trackMbid);
  }

  int? getFavoriteId(String trackMbid) {
    for (final item in _likedItems) {
      if (item['track']?.id == trackMbid) {
        return item['id'] as int?;
      }
    }
    return null;
  }

  Future<void> toggleLike(Track track) async {
    final isCurrentlyLiked = isLiked(track.id);
    try {
      if (isCurrentlyLiked) {
        final favId = getFavoriteId(track.id);
        if (favId != null) {
          await _api.unlikeTrack(favId);
          _likedItems.removeWhere((item) => item['track'].id == track.id);
        }
      } else {
        final newFav = await _api.likeTrack(track.id);
        _likedItems.add({
          'id': newFav['id'],
          'track': track,
        });
      }
      notifyListeners();
    } catch (e) {
    }
  }
}