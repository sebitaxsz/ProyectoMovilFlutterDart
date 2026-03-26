import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _token != null;
  String? get token => _token;

  AuthProvider() {
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_data');
    
    if (token != null && userJson != null) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userJson);
        _token = token;
        _currentUser = User.fromJson({'token': token, 'user': userData});
        notifyListeners();
      } catch (e) {
        print('Error loading user: $e');
      }
    }
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', user.token);
    await prefs.setString('user_data', jsonEncode({
      'user_id': user.userId,
      'username': user.username,
      'role': user.role,
      'entity': user.entity?.toJson(),
    }));
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _apiService.login(username, password);
      _currentUser = user;
      _token = user.token;
      await _saveUser(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(userData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _currentUser = null;
    _token = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _apiService.requestPasswordReset(email);
    _isLoading = false;
    notifyListeners();
    return response;
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return {'ok': false, 'message': e.toString()};
  }
}

// Verificar código de recuperación
Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _apiService.verifyResetCode(email, code);
    _isLoading = false;
    notifyListeners();
    return response;
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return {'ok': false, 'message': e.toString()};
  }
}

Future<Map<String, dynamic>> resetPassword(
  String email, 
  String code, 
  String newPassword, 
  String confirmPassword
) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _apiService.resetPassword(email, code, newPassword, confirmPassword);
    _isLoading = false;
    notifyListeners();
    return response;
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return {'ok': false, 'message': e.toString()};
  }
}
}
