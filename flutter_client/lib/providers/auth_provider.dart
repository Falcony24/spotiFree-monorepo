import 'package:flutter/material.dart';
import 'package:spotifree/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final AuthService _authService = AuthService();

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _authService.getAccessToken();
      _isAuthenticated = token != null;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.login(username, password);
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.register(username, password);
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}