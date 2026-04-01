import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModeProvider extends ChangeNotifier {
  bool _isOfflineMode = false;
  bool get isOfflineMode => _isOfflineMode;

  ModeProvider() {
    _loadMode();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('offline_mode') ?? false;
    notifyListeners();
  }

  Future<void> setOfflineMode(bool value) async {
    if (_isOfflineMode == value) return;
    _isOfflineMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', value);
    notifyListeners();
  }
}