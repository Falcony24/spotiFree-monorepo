import 'package:flutter/material.dart';
import 'package:spotifree/domain/usecases/search_use_case.dart';
import 'package:spotifree/models/artist.dart';
import 'package:spotifree/models/album.dart';
import 'package:spotifree/models/track.dart';
import 'package:spotifree/providers/mode_provider.dart';

class SearchProvider extends ChangeNotifier {
  final SearchUseCase _searchUseCase;
  final ModeProvider _modeProvider;

  List<Artist> _artists = [];
  List<Album> _albums = [];
  List<Track> _tracks = [];
  bool _isLoading = false;
  String? _error;
  String? _lastQuery;

  List<Artist> get artists => _artists;
  List<Album> get albums => _albums;
  List<Track> get tracks => _tracks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastQuery => _lastQuery;

  SearchProvider({
    required SearchUseCase searchUseCase,
    required ModeProvider modeProvider,
  })  : _searchUseCase = searchUseCase,
        _modeProvider = modeProvider;

Future<void> search(String query, {String? type}) async {
  if (query.isEmpty) {
    _clearResults();
    return;
  }

  if (_modeProvider.isOfflineMode) {
    _clearResults();
    _error = 'Tryb offline – wyszukiwanie niedostępne';
    notifyListeners();
    return;
  }

  _lastQuery = query;
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final results = await _searchUseCase.execute(query, type: type);

    _artists = (results['artists']?['data'] as List?)?.cast<Artist>() ?? [];
    _albums = (results['albums']?['data'] as List?)?.cast<Album>() ?? [];
    _tracks = (results['tracks']?['data'] as List?)?.cast<Track>() ?? [];

    if (_artists.isEmpty && _albums.isEmpty && _tracks.isEmpty) {
      _error = 'Brak wyników';
    }
  } catch (e, stack) {
    _error = 'Błąd wyszukiwania: $e';
    _artists = [];
    _albums = [];
    _tracks = [];
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  void _clearResults() {
    _artists = [];
    _albums = [];
    _tracks = [];
    _error = null;
    _lastQuery = null;
    notifyListeners();
  }

  void clear() {
    _clearResults();
  }
}