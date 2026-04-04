import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ModeProvider extends ChangeNotifier {
  bool _isOfflineMode = false;
  bool _hasInternet = true;

  bool get isOfflineMode => _isOfflineMode;
  bool get hasInternet => _hasInternet;

  ModeProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadMode();
    await _checkInitialConnectivity();
    _monitorConnectivity();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('offline_mode') ?? false;
    notifyListeners();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _hasInternet = result != ConnectivityResult.none;
    if (!_hasInternet && !_isOfflineMode) {
      _isOfflineMode = true;
      await _saveMode();
    }
    notifyListeners();
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final previousInternet = _hasInternet;
      _hasInternet = result != ConnectivityResult.none;
      if (!_hasInternet && !_isOfflineMode) {
        _isOfflineMode = true;
        _saveMode();
        debugPrint('Brak internetu – przełączono w tryb offline');
      } else if (_hasInternet && !previousInternet) {
        debugPrint('Internet przywrócony – możesz wyłączyć tryb offline');
      }
      notifyListeners();
    });
  }

  Future<void> setOfflineMode(bool value) async {
    if (!_hasInternet && !value) {
      debugPrint('Nie można wyłączyć trybu offline – brak internetu');
      return;
    }
    if (_isOfflineMode == value) return;
    _isOfflineMode = value;
    await _saveMode();
    notifyListeners();
  }

  Future<void> _saveMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', _isOfflineMode);
  }
}