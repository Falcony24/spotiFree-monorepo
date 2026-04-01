import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/api_service.dart';

class PlaylistTracksProvider extends ChangeNotifier {
  List<Track> _tracks = [];
  bool _isLoading = false;
  String? _error;

  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTracks(int playlistId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService().getPlaylistDetail(playlistId);
      _tracks = List<Track>.from(data['tracks']);
    } catch (e) {
      _error = e.toString();
      _tracks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}