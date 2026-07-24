import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ModeProvider extends ChangeNotifier {
  bool _isOfflineMode = false;
  bool _hasInternet = true;
  bool _autoOffline = false;
  StreamSubscription? _connectionSubscription;

  bool get isOfflineMode => _isOfflineMode;
  bool get hasInternet => _hasInternet;

  final InternetConnectionChecker _connectionChecker = InternetConnectionChecker();

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
    _autoOffline = false;
    notifyListeners();
  }

  Future<void> _checkInitialConnectivity() async {
    _hasInternet = await _connectionChecker.hasConnection;
    if (!_hasInternet && !_isOfflineMode) {
      _isOfflineMode = true;
      _autoOffline = true;
    }
    notifyListeners();
  }

  void _monitorConnectivity() {
    _connectionSubscription = _connectionChecker.onStatusChange.listen((status) {
      final previousInternet = _hasInternet;
      _hasInternet = (status == InternetConnectionStatus.connected);

      if (!_hasInternet && !_isOfflineMode) {
        _isOfflineMode = true;
        _autoOffline = true;
        debugPrint('No internet — switched to offline mode');
      } else if (_hasInternet && !previousInternet && _autoOffline) {
        _isOfflineMode = false;
        _autoOffline = false;
        debugPrint('Internet restored — switched back to online mode');
      }
      notifyListeners();
    });
  }

  Future<void> setOfflineMode(bool value) async {
    if (!_hasInternet && !value) {
      debugPrint('Cannot disable offline mode — no internet');
      return;
    }
    if (_isOfflineMode == value) return;

    _isOfflineMode = value;
    _autoOffline = false; 
    await _saveMode();
    notifyListeners();
  }

  Future<void> _saveMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', _isOfflineMode);
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}