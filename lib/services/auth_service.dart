import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_system/models/user_model.dart';
import 'package:ticket_system/services/api_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.login(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        _user = UserModel.fromJson(result['user']);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Login failed');
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Login with Google - Local authentication only (no backend API)
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Sign out first to ensure clean state
      await googleSignIn.signOut();

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _setError('Sign-in was cancelled by user');
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Save user info locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', googleUser.email);
      await prefs.setString('user_name', googleUser.displayName ?? '');
      await prefs.setString('user_photo', googleUser.photoUrl ?? '');
      if (googleAuth.idToken != null) {
        await prefs.setString('id_token', googleAuth.idToken!);
      }

      // Create user model from Google account
      _user = UserModel(
        id: 0, // Local ID
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Google sign-in failed: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Register user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await ApiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (result['success'] == true) {
        _user = UserModel.fromJson(result['user']);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] ?? 'Registration failed');
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await ApiService.logout();
      _user = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      // Even if logout fails on server, clear local data
      _user = null;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    
    try {
      final isAuth = await ApiService.isAuthenticated();
      if (isAuth) {
        final result = await ApiService.getUserProfile();
        if (result['success'] == true) {
          _user = UserModel.fromJson(result['user']);
        } else {
          // Token might be invalid, clear it
          await ApiService.clearAuthData();
        }
      }
    } catch (e) {
      // Handle error silently
    }
    
    _setLoading(false);
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}





