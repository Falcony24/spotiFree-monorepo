import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/offline_storage.dart';

class LikedTracksProvider extends ChangeNotifier {
  final OfflineStorage _storage = OfflineStorage();
  final ApiService _api = ApiService();
  ModeProvider? _modeProvider;

  List<Map<String, dynamic>> _likedItems = [];
  bool _isLoading = false;      
  bool _isRefreshing = false;   
  String? _error;

  List<Map<String, dynamic>> get likedItems => _likedItems;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  void setModeProvider(ModeProvider modeProvider) {
    _modeProvider = modeProvider;
  }

  Future<void> fetchLikedTracks({bool forceRefresh = false}) async {
    final isOffline = _modeProvider?.isOfflineMode == true;

    if (isOffline) {
      await _loadFromOffline();
      return;
    }

    final cachedItems = await _storage.getLikedTracks();
    if (!forceRefresh && cachedItems.isNotEmpty) {
      _likedItems = cachedItems;
      notifyListeners();
    } else if (_likedItems.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    _isRefreshing = true;
    notifyListeners();

    try {
      final freshItems = await _api.getLikedTracks();
      _likedItems = freshItems;
      _error = null;

      final allOld = await _storage.getLikedTracks();
      for (final old in allOld) {
        await _storage.removeLikedTrack(old['track'].id);
      }
      for (final item in freshItems) {
        await _storage.addLikedTrack(item['id'], item['track']);
      }
    } catch (e) {
      if (_likedItems.isEmpty) {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromOffline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _likedItems = await _storage.getLikedTracks();
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

  Future<int?> getFavoriteId(String trackMbid) async {
    return await _storage.getFavoriteIdForTrack(trackMbid);
  }

  Future<void> toggleLike(Track track) async {
    final isCurrentlyLiked = await _storage.isTrackLiked(track.id);
    try {
      if (isCurrentlyLiked) {
        if (_modeProvider?.isOfflineMode != true) {
          final favId = await _storage.getFavoriteIdForTrack(track.id);
          if (favId != null) await _api.unlikeTrack(favId);
        }
        await _storage.removeLikedTrack(track.id);
        if (_modeProvider?.isOfflineMode == true) {
          await _storage.addToSyncQueue('liked_track', 'remove', track.id);
        }
      } else {
        int newFavId;
        if (_modeProvider?.isOfflineMode != true) {
          final newFav = await _api.likeTrack(track.id);
          newFavId = newFav['id'];
        } else {
          newFavId = -1;
          await _storage.addToSyncQueue('liked_track', 'add', track.id,
              payload: jsonEncode(track.toJson()));
        }
        await _storage.addLikedTrack(newFavId, track);
      }
      await fetchLikedTracks(forceRefresh: true);
    } catch (e) {
      debugPrint('Błąd podczas zmiany stanu polubienia: $e');
    }
  }

  Future<void> refresh() async {
    await fetchLikedTracks(forceRefresh: true);
  }
}