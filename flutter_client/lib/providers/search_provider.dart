import 'package:flutter/material.dart';
import 'package:frontend/domain/usecases/search_use_case.dart';
import 'package:frontend/models/artist.dart';
import 'package:frontend/models/album.dart';
import 'package:frontend/models/track.dart';
import 'package:frontend/providers/mode_provider.dart';

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
      _isLoading = false;
      _error = '';
      _artists = [];
      _albums = [];
      _tracks = [];
      notifyListeners();
      return;
    }

    _lastQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _searchUseCase.execute(query, type: type);
      _artists = results['artists']['data'] as List<Artist>;
      _albums = results['albums']['data'] as List<Album>;
      _tracks = results['tracks']['data'] as List<Track>;
    } catch (e) {
      _error = e.toString();
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