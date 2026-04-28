import 'package:flutter/material.dart';
import 'package:frontend/domain/usecases/get_artist_use_case.dart';
import 'package:frontend/providers/mode_provider.dart';
import 'package:frontend/models/artist.dart';

class ArtistDetailsProvider extends ChangeNotifier {
  final GetArtistUseCase getArtistUseCase;
  final ModeProvider modeProvider;

  Artist? _artist;
  bool _isLoading = false;
  String? _error;
  String? _currentArtistId;

  Artist? get artist => _artist;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ArtistDetailsProvider({
    required this.getArtistUseCase,
    required this.modeProvider,
  }) {
    modeProvider.addListener(_onModeChanged);
  }

  void _onModeChanged() {
    if (_currentArtistId  != null) {
      fetchArtist(_currentArtistId!);
    }
  }

  Future<void> fetchArtist(String artistId) async {
    if (_currentArtistId == artistId && _artist != null) return;

    _artist = null;
    _error = null;
    _currentArtistId = artistId;
    _isLoading = true;
    notifyListeners();

    try {
      _artist = await getArtistUseCase.execute(artistId);
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
    _currentArtistId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}