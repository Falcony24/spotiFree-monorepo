import 'package:flutter/material.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/services/api_service.dart';

class ArtistDetailsProvider extends ChangeNotifier {
  Artist? _artist;
  bool _isLoading = false;
  String? _error;
  bool _hasLoadedOnce = false;  

  Artist? get artist => _artist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final ApiService _api = ApiService();

  Future<void> fetchArtist(String artistId) async {
    if (_hasLoadedOnce) return;
    _hasLoadedOnce = true;

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getArtist(artistId);
      _artist = Artist.fromJson(data);
    } catch (e) {
      _error = e.toString();
      _artist = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _artist = null;
    _isLoading = false;
    _error = null;
    _hasLoadedOnce = false;
    notifyListeners();
  }
}