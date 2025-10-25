// lib/providers/auth_provider.dart - Authentication state provider
import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:smart_parking_app/models/user.dart';
import 'package:smart_parking_app/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;
  
  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      _currentUser = await _authRepository.getCurrentUser();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // Register user
  Future<bool> register(String username, String email, String password, String name, String phoneNumber) async {
    _setLoading(true);
    try {
      _currentUser = await _authRepository.register(username, email, password, name, phoneNumber);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Login user
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authRepository.login(email, password);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Update user profile
  Future<bool> updateProfile({String? name, String? phoneNumber}) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      _currentUser = await _authRepository.updateProfile(
        _currentUser!,
        name: name,
        phoneNumber: phoneNumber
      );
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;
    
    _setLoading(true);
    try {
      await _authRepository.changePassword(_currentUser!, currentPassword, newPassword);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authRepository.resetPassword(email);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Helper to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
