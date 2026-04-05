import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_liked_storage.dart';

class LikedTracksProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _likedItems = [];
  bool _isLoading = false;
  String? _error;
  ModeProvider? _modeProvider;

  List<Map<String, dynamic>> get likedItems => _likedItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();
  final OfflineLikedStorage _offlineStorage = OfflineLikedStorage();

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchLikedTracks() async {
    if (_modeProvider?.isOfflineMode == true) {
      await _loadFromOffline();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _likedItems = await _api.getLikedTracks();
      await _offlineStorage.saveLikedTracks(_likedItems);
    } catch (e) {
      _error = e.toString();
      _likedItems = [];
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
      _likedItems = await _offlineStorage.loadLikedTracks();
      if (_likedItems.isEmpty) {
        _error = 'Brak polubionych utworów w trybie offline.';
      }
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
          if (_modeProvider?.isOfflineMode != true) {
            await _api.unlikeTrack(favId);
          }
          _likedItems.removeWhere((item) => item['track'].id == track.id);
          await _offlineStorage.removeLikedTrack(track.id);
        }
      } else {
        int newFavId;
        if (_modeProvider?.isOfflineMode != true) {
          final newFav = await _api.likeTrack(track.id);
          newFavId = newFav['id'];
        } else {
          debugPrint('Nie można polubić utworu w trybie offline');
          return;
        }
        _likedItems.add({
          'id': newFavId,
          'track': track,
        });
        await _offlineStorage.addLikedTrack(newFavId, track);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Błąd podczas zmiany stanu polubienia: $e');
    }
  }
}