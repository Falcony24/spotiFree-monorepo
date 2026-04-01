import 'package:flutter/material.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/services/api_service.dart';

class AlbumDetailProvider extends ChangeNotifier {
  final String albumId;
  List<Track> _tracks = [];
  bool _isLoadingTracks = false;
  String? _errorTracks;

  AlbumDetailProvider(this.albumId) {
    fetchTracks();
  }

  List<Track> get tracks => _tracks;
  bool get isLoadingTracks => _isLoadingTracks;
  String? get errorTracks => _errorTracks;

  Future<void> fetchTracks() async {
    _isLoadingTracks = true;
    _errorTracks = null;
    notifyListeners();
    try {
      final tracks = await ApiService().getAlbumTracks(albumId);
      _tracks = tracks;
    } catch (e) {
      _errorTracks = e.toString();
    } finally {
      _isLoadingTracks = false;
      notifyListeners();
    }
  }
}