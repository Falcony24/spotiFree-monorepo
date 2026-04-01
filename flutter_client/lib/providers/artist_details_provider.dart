import 'package:flutter/material.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/services/api_service.dart';

class ArtistDetailsProvider extends ChangeNotifier {
  Artist? _artist;
  bool _isLoading = false;
  String? _error;

  Artist? get artist => _artist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchArtist(String artistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getArtist(artistId);
      _artist = Artist.fromJson(data);
    } catch (e) {
      _error = e.toString();
      _artist = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}