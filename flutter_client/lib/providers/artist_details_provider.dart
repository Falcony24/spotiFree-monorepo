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
  bool _hasLoadedOnce = false;

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
    if (_artist != null) {
      fetchArtist(_artist!.id);
    }
  }

  Future<void> fetchArtist(String artistId) async {
    if (_hasLoadedOnce) return;
    _hasLoadedOnce = true;

    _isLoading = true;
    _error = null;
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
    _hasLoadedOnce = false;
    notifyListeners();
  }

  @override
  void dispose() {
    modeProvider.removeListener(_onModeChanged);
    super.dispose();
  }
}