import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/purchase_request_model.dart';

class TeamLeaderApi {
  static Dio? _dio;

  static Dio get dio {
    if (_dio == null) {
      print('🔧 TeamLeaderApi: Initializing Dio instance');
      print('   AppConfig.apiBaseUrl: ${AppConfig.apiBaseUrl}');
      
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // Don't throw exceptions for status codes, handle them manually
          validateStatus: (status) {
            return status != null && status < 500; // Accept all status codes < 500
          },
        ),
      );
      
      print('✅ TeamLeaderApi: Dio instance created');
      print('   Dio baseUrl: ${_dio!.options.baseUrl}');

      // Add interceptor for token
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              print('🔑 Auth Token: ${token.substring(0, 20)}... (truncated)');
            } else {
              print('⚠️ No auth token found!');
            }
            // Log the full URL being called
            final fullUrl = '${options.baseUrl}${options.path}';
            print('═══════════════════════════════════════════════════════');
            print('🌐 TeamLeaderApi REQUEST:');
            print('   Method: ${options.method}');
            print('   Base URL: ${options.baseUrl}');
            print('   Path: ${options.path}');
            print('   Full URL: $fullUrl');
            print('   Headers:');
            options.headers.forEach((key, value) {
              if (key == 'Authorization') {
                print('     $key: Bearer ${value.toString().substring(7, 27)}... (truncated)');
              } else {
                print('     $key: $value');
              }
            });
            if (options.data != null) {
              print('   Body: ${options.data}');
            }
            print('═══════════════════════════════════════════════════════');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            print('═══════════════════════════════════════════════════════');
            print('📥 TeamLeaderApi RESPONSE:');
            print('   Status Code: ${response.statusCode}');
            print('   Status Message: ${response.statusMessage}');
            print('   Headers:');
            response.headers.forEach((key, values) {
              print('     $key: ${values.join(", ")}');
            });
            print('   Response Data Type: ${response.data.runtimeType}');
            print('   Response Data:');
            try {
              // Pretty print JSON if possible
              if (response.data is Map || response.data is List) {
                print('     ${response.data}');
              } else {
                print('     ${response.data.toString()}');
              }
            } catch (e) {
              print('     (Could not print response data: $e)');
            }
            print('═══════════════════════════════════════════════════════');
            return handler.next(response);
          },
          onError: (error, handler) {
            print('═══════════════════════════════════════════════════════');
            print('❌ TeamLeaderApi ERROR:');
            print('   Request URL: ${error.requestOptions.baseUrl}${error.requestOptions.path}');
            print('   Status Code: ${error.response?.statusCode}');
            print('   Status Message: ${error.response?.statusMessage}');
            print('   Error Type: ${error.type}');
            print('   Error Message: ${error.message}');
            if (error.response != null) {
              print('   Response Headers:');
              error.response!.headers.forEach((key, values) {
                print('     $key: ${values.join(", ")}');
              });
              print('   Response Data:');
              try {
                if (error.response!.data is Map || error.response!.data is List) {
                  print('     ${error.response!.data}');
                } else {
                  print('     ${error.response!.data.toString()}');
                }
              } catch (e) {
                print('     (Could not print error response data: $e)');
              }
            } else {
              print('   No response received (network error?)');
            }
            print('═══════════════════════════════════════════════════════');
            
            // Handle 401, 403 errors
            if (error.response?.statusCode == 401) {
              // Unauthorized - token expired or invalid
              print('❌ 401 Unauthorized - Token may be expired or invalid');
            } else if (error.response?.statusCode == 403) {
              // Forbidden - no permission
              print('❌ 403 Forbidden - User does not have permission');
            } else if (error.response?.statusCode == 404) {
              print('❌ 404 Not Found - Endpoint does not exist');
            }
            return handler.next(error);
          },
        ),
      );
    }
    return _dio!;
  }

  /// Get list of purchase requests
  static Future<List<PurchaseRequestModel>> getPurchaseRequests() async {
    try {
      print('🚀 CALLING: TeamLeaderApi.getPurchaseRequests()');
      print('   Endpoint: /purchase-requests');
      print('   Base URL from config: ${AppConfig.apiBaseUrl}');
      print('   Expected full URL: ${AppConfig.apiBaseUrl}/purchase-requests');
      
      final response = await dio.get('/purchase-requests');
      
      print('✅ RECEIVED RESPONSE: TeamLeaderApi.getPurchaseRequests()');
      print('   Status Code: ${response.statusCode}');
      print('   Response Type: ${response.data.runtimeType}');
      print('   Raw Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> requestsList = [];
        
        print('📊 Parsing response data...');
        print('   Data type: ${data.runtimeType}');
        
        if (data is Map) {
          print('   Data is Map, keys: ${data.keys.toList()}');
          
          // Check if it's a success response with nested data
          if (data['success'] == true && data['data'] != null) {
            final responseData = data['data'];
            print('   responseData type: ${responseData.runtimeType}');
            
            // Check if responseData is a pagination object with 'data' key
            if (responseData is Map && responseData['data'] != null) {
              if (responseData['data'] is List) {
                requestsList = responseData['data'] as List;
                print('   ✅ Found list in data["data"]["data"] with ${requestsList.length} items');
              } else {
                print('   ⚠️ responseData["data"] is not a List, it is: ${responseData['data'].runtimeType}');
              }
            } else if (responseData is List) {
              requestsList = responseData;
              print('   ✅ responseData is directly a List with ${requestsList.length} items');
            }
          } else if (data['data'] != null) {
            // Fallback: check if data['data'] is directly a list
            if (data['data'] is List) {
              requestsList = data['data'] as List;
              print('   ✅ Found list in data["data"] with ${requestsList.length} items');
            } else if (data['data'] is Map && data['data']['data'] != null && data['data']['data'] is List) {
              // Handle pagination structure: data.data.data
              requestsList = data['data']['data'] as List;
              print('   ✅ Found list in data["data"]["data"] with ${requestsList.length} items');
            }
          } else {
            print('   ⚠️ No "data" key found in response');
          }
        } else if (data is List) {
          requestsList = data;
          print('   ✅ Data is directly a List with ${requestsList.length} items');
        } else {
          print('   ⚠️ Data is neither Map nor List: ${data.runtimeType}');
        }
        
        if (requestsList.isNotEmpty) {
          print('✅ TeamLeaderApi: Successfully parsed ${requestsList.length} purchase requests');
          print('   First item sample: ${requestsList.first}');
        } else {
          print('⚠️ TeamLeaderApi: No purchase requests found in response');
        }
        
        return requestsList
            .map((json) {
              try {
                return PurchaseRequestModel.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print('❌ Error parsing purchase request: $e');
                print('   JSON: $json');
                rethrow;
              }
            })
            .toList();
      }
      print('⚠️ TeamLeaderApi: Unexpected status code: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      print('❌ TeamLeaderApi: DioException getting purchase requests');
      print('   Status code: ${e.response?.statusCode}');
      print('   Message: ${e.message}');
      print('   Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      
      // Handle 404 - endpoint might not exist, return empty list
      if (e.response?.statusCode == 404) {
        print('⚠️ TeamLeaderApi: Endpoint not found (404). The /purchase-requests endpoint may not be available.');
        return [];
      }
      
      return [];
    } catch (e, stackTrace) {
      print('❌ TeamLeaderApi: Unexpected error: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get single purchase request by ID
  static Future<PurchaseRequestModel?> getPurchaseRequestById(int id) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('📡 TeamLeaderApi.getPurchaseRequestById($id)');
      print('   Endpoint: /purchase-requests/$id');
      print('   Base URL from config: ${AppConfig.apiBaseUrl}');
      print('   Expected full URL: ${AppConfig.apiBaseUrl}/purchase-requests/$id');
      print('═══════════════════════════════════════════════════════');
      
      final response = await dio.get('/purchase-requests/$id');
      
      print('📥 TeamLeaderApi.getPurchaseRequestById() Response:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> requestData;
        
        if (data is Map && data['data'] is Map) {
          requestData = data['data'] as Map<String, dynamic>;
        } else if (data is Map) {
          requestData = data as Map<String, dynamic>;
        } else {
          print('⚠️ TeamLeaderApi: Data is not a Map');
          return null;
        }
        
        print('✅ TeamLeaderApi: Successfully parsed purchase request');
        return PurchaseRequestModel.fromJson(requestData);
      }
      print('⚠️ TeamLeaderApi: Unexpected status code: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print('❌ TeamLeaderApi: DioException getting purchase request');
      print('   Status code: ${e.response?.statusCode}');
      print('   Message: ${e.message}');
      print('   Response data: ${e.response?.data}');
      
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        rethrow;
      }
      
      // Handle 404 - endpoint might not exist
      if (e.response?.statusCode == 404) {
        print('⚠️ TeamLeaderApi: Endpoint not found (404). The /purchase-requests/$id endpoint may not be available.');
        return null;
      }
      
      return null;
    } catch (e, stackTrace) {
      print('❌ TeamLeaderApi: Unexpected error: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Approve purchase request
  static Future<Map<String, dynamic>> approvePurchaseRequest(int id) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('📡 TeamLeaderApi.approvePurchaseRequest($id)');
      print('   Endpoint: /purchase-requests/$id/approve');
      print('   Base URL from config: ${AppConfig.apiBaseUrl}');
      print('   Expected full URL: ${AppConfig.apiBaseUrl}/purchase-requests/$id/approve');
      print('   Method: POST');
      print('═══════════════════════════════════════════════════════');
      
      final response = await dio.post('/purchase-requests/$id/approve');
      
      print('📥 TeamLeaderApi.approvePurchaseRequest() Response:');
      print('   Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message']?.toString() ?? 'Purchase request approved successfully',
        };
      }
      return {
        'success': false,
        'message': 'Failed to approve purchase request',
      };
    } on DioException catch (e) {
      print('❌ Error approving purchase request: ${e.message}');
      String errorMessage = 'Failed to approve purchase request';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Unauthorized. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'You do not have permission to approve this request.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Reject purchase request
  static Future<Map<String, dynamic>> rejectPurchaseRequest(
    int id,
    String reason,
  ) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('📡 TeamLeaderApi.rejectPurchaseRequest($id)');
      print('   Endpoint: /purchase-requests/$id/reject');
      print('   Base URL from config: ${AppConfig.apiBaseUrl}');
      print('   Expected full URL: ${AppConfig.apiBaseUrl}/purchase-requests/$id/reject');
      print('   Method: POST');
      print('   Reason: $reason');
      print('═══════════════════════════════════════════════════════');
      
      final response = await dio.post(
        '/purchase-requests/$id/reject',
        data: {'reason': reason},
      );
      
      print('📥 TeamLeaderApi.rejectPurchaseRequest() Response:');
      print('   Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message']?.toString() ?? 'Purchase request rejected successfully',
        };
      }
      return {
        'success': false,
        'message': 'Failed to reject purchase request',
      };
    } on DioException catch (e) {
      print('❌ Error rejecting purchase request: ${e.message}');
      String errorMessage = 'Failed to reject purchase request';
      
      if (e.response?.statusCode == 401) {
        errorMessage = 'Unauthorized. Please login again.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'You do not have permission to reject this request.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }
}

