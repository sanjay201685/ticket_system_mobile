import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_system/config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  
  // Headers for API requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get headers with authorization token
  static Future<Map<String, String>> get authHeaders async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Login user with email and password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.loginEndpoint}'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store auth token
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.registerEndpoint}'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Store auth token
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${AppConfig.userEndpoint}'),
        headers: await authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Logout user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.logoutEndpoint}'),
        headers: await authHeaders,
      );

      // Clear stored token regardless of response
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Logged out successfully',
        };
      } else {
        return {
          'success': true, // Still consider it successful since we cleared the token
          'message': 'Logged out successfully',
        };
      }
    } catch (e) {
      // Clear token even if network error
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      
      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null;
  }

  /// Get stored auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Login with Google (send ID token to Laravel backend)
  static Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.googleLoginEndpoint}'),
        headers: headers,
        body: jsonEncode({
          'id_token': idToken,
          if (accessToken != null) 'access_token': accessToken,
          'provider': 'google',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Store auth token
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Google login successful',
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Google login failed',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Clear all stored data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
