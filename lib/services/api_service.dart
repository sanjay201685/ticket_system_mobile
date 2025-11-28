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
      final url = '$baseUrl${AppConfig.loginEndpoint}';
      print('🔐 Login attempt to: $url');
      print('📧 Email: $email');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(
        Duration(seconds: AppConfig.requestTimeout),
        onTimeout: () {
          throw Exception('Request timeout after ${AppConfig.requestTimeout} seconds');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      // Check if response body is empty
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Empty response from server. Please check your API endpoint.',
        };
      }

      // Try to parse JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ JSON decode error: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}',
        };
      }

      // Check for token first - if no token, it's definitely an error
      final hasToken = data['token'] != null || data['access_token'] != null;
      
      // Handle successful response (200 or 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // If no token, it's an error regardless of status code
        if (!hasToken) {
          print('⚠️ Status 200/201 but no token found - treating as error');
          return _extractErrorMessage(data);
        }

        // Check if response message indicates an error
        if (data.containsKey('message') && data['message'] != null) {
          final message = data['message'].toString().toLowerCase();
          // Check if message indicates an error
          if (message.contains('invalid') || 
              message.contains('incorrect') || 
              message.contains('wrong') ||
              message.contains('failed') ||
              message.contains('unauthorized') ||
              message.contains('error') ||
              message.contains('credentials')) {
            print('⚠️ Status 200/201 but message indicates error - treating as error');
            return _extractErrorMessage(data);
          }
        }

        // Store auth token
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'] ?? data['access_token'];
        await prefs.setString('auth_token', token.toString());
        print('✅ Token stored successfully');

        // Check if user data exists
        if (data['user'] == null && data['data'] == null) {
          print('⚠️ No user data in response');
          return {
            'success': false,
            'message': 'User data not found in response',
          };
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'] ?? data['data'],
          'token': data['token'] ?? data['access_token'],
        };
      } else {
        // Handle error responses (401, 422, 500, etc.)
        print('❌ Error status code: ${response.statusCode}');
        return _extractErrorMessage(data);
      }
    } catch (e) {
      print('❌ Login error: $e');
      String errorMessage = 'Network error: ${e.toString()}';
      
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Please check your internet connection and API URL.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please try again.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
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

  /// Extract error message from Laravel response
  static Map<String, dynamic> _extractErrorMessage(Map<String, dynamic> data) {
    print('🔍 Extracting error from data: $data');
    
    String errorMessage = 'Invalid credentials. Please check your email and password.';
    
    // Try to extract error message from different Laravel response formats
    // Priority 1: Check 'message' field
    if (data.containsKey('message') && data['message'] != null) {
      final msg = data['message'].toString().trim();
      if (msg.isNotEmpty) {
        errorMessage = msg;
        print('✅ Found error in message field: $errorMessage');
      }
    } 
    // Priority 2: Check 'error' field
    else if (data.containsKey('error') && data['error'] != null) {
      final err = data['error'].toString().trim();
      if (err.isNotEmpty) {
        errorMessage = err;
        print('✅ Found error in error field: $errorMessage');
      }
    } 
    // Priority 3: Check 'errors' object (Laravel validation errors)
    else if (data.containsKey('errors') && data['errors'] != null) {
      final errors = data['errors'];
      print('🔍 Processing errors object: $errors');
      
      if (errors is Map && errors.isNotEmpty) {
        // Laravel validation errors: {"errors": {"email": ["The email field is required."]}}
        // Try to get first error value
        final firstKey = errors.keys.first;
        final firstValue = errors[firstKey];
        
        if (firstValue is List && firstValue.isNotEmpty) {
          errorMessage = firstValue.first.toString().trim();
          print('✅ Found error in errors[list]: $errorMessage');
        } else if (firstValue is String && firstValue.trim().isNotEmpty) {
          errorMessage = firstValue.trim();
          print('✅ Found error in errors[string]: $errorMessage');
        } else {
          errorMessage = firstValue.toString().trim();
          print('✅ Found error in errors[other]: $errorMessage');
        }
      } else if (errors is List && errors.isNotEmpty) {
        errorMessage = errors.first.toString().trim();
        print('✅ Found error in errors list: $errorMessage');
      } else if (errors is String && errors.trim().isNotEmpty) {
        errorMessage = errors.trim();
        print('✅ Found error in errors string: $errorMessage');
      }
    }

    // Clean up error message - remove brackets and extra whitespace
    errorMessage = errorMessage
        .replaceAll(RegExp(r'\[|\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Final fallback if message is still empty
    if (errorMessage.isEmpty || errorMessage == 'null') {
      errorMessage = 'Invalid credentials. Please check your email and password.';
      print('⚠️ Using default error message');
    }

    print('❌ FINAL Extracted error message: $errorMessage');
    
    return {
      'success': false,
      'message': errorMessage,
      'errors': data['errors'],
    };
  }
}
