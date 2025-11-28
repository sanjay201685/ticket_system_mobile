import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiClient {
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Get headers with authorization token
  static Future<Map<String, String>> get headers async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request
  static Future<http.Response> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('📡 GET: $url');
      
      final response = await http.get(
        url,
        headers: await headers,
      ).timeout(
        Duration(seconds: AppConfig.requestTimeout),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      return response;
    } catch (e) {
      print('❌ GET error: $e');
      rethrow;
    }
  }

  /// POST request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      print('📡 POST: $url');
      print('📤 Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        url,
        headers: await headers,
        body: jsonEncode(body),
      ).timeout(
        Duration(seconds: AppConfig.requestTimeout),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');
      return response;
    } catch (e) {
      print('❌ POST error: $e');
      rethrow;
    }
  }

  /// Handle API response
  static Map<String, dynamic> handleResponse(http.Response response) {
    print('=== handleResponse ===');
    print('Status code: ${response.statusCode}');
    print('Response body length: ${response.body.length}');
    
    if (response.body.isEmpty) {
      print('⚠️ Empty response body');
      return {
        'success': false,
        'message': 'Empty response from server',
      };
    }

    try {
      print('Raw response body: ${response.body}');
      final data = jsonDecode(response.body);
      print('Parsed JSON data type: ${data.runtimeType}');
      
      // Handle success responses (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Success response (${response.statusCode})');
        
        // Handle different response formats
        if (data is Map) {
          print('Data is Map, keys: ${data.keys.toList()}');
          
          // Check if response has success field (might be false even with 200 status)
          if (data.containsKey('success')) {
            final isSuccess = data['success'] == true;
            print('Response has success field: $isSuccess');
            
            if (!isSuccess) {
              // Success field is false, treat as error
              return {
                'success': false,
                'message': data['message']?.toString() ?? 'Request failed',
                'errors': data['errors'],
              };
            }
          }
          
          // Laravel API typically returns {data: [...]} for successful requests
          if (data.containsKey('data')) {
            final extractedData = data['data'];
            print('Found "data" key, type: ${extractedData.runtimeType}');
            if (extractedData is List) {
              print('Extracted data is List with ${extractedData.length} items');
            }
            return {
              'success': true,
              'data': extractedData, // Extract the actual data array
            };
          }
          
          // Map without data key - return as-is
          print('Map without data key, returning as-is');
          return {
            'success': true,
            'data': data,
          };
        } else if (data is List) {
          // API returned array directly (e.g., [{...}, {...}])
          print('✅ Data is List directly, length: ${data.length}');
          return {
            'success': true,
            'data': data,
          };
        } else {
          // Other types (String, int, etc.)
          print('Data is ${data.runtimeType}, returning as-is');
          return {
            'success': true,
            'data': data,
          };
        }
      } else {
        // Handle error responses (400+)
        print('❌ Error response (${response.statusCode})');
        String errorMessage = 'Request failed';
        Map<String, dynamic>? errors;
        
        if (data is Map) {
          // Laravel validation errors (422) typically have 'message' and 'errors'
          errorMessage = data['message']?.toString() ?? 
                        data['error']?.toString() ?? 
                        'Validation failed';
          print('Error message: $errorMessage');
          
          // Extract validation errors if present (Laravel format)
          if (data.containsKey('errors')) {
            final errorsData = data['errors'];
            if (errorsData is Map) {
              errors = Map<String, dynamic>.from(errorsData);
              print('Validation errors (Map): $errors');
            } else if (errorsData is List) {
              // Convert list to map format
              errors = {'general': errorsData};
              print('Validation errors (List): $errors');
            }
          }
        } else if (data is String) {
          errorMessage = data;
        }
        
        return {
          'success': false,
          'message': errorMessage,
          'errors': errors,
        };
      }
    } catch (e) {
      print('❌ JSON parse error: $e');
      print('Response body: ${response.body}');
      return {
        'success': false,
        'message': 'Invalid response format: ${e.toString()}',
      };
    }
  }
}


