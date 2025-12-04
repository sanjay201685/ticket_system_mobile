import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/stock_order_model.dart';

class StockOrderApi {
  static Dio? _dio;

  static Dio get dio {
    if (_dio == null) {
      print('🔧 StockOrderApi: Initializing Dio instance');
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
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      print('✅ StockOrderApi: Dio instance created');
      print('   Dio baseUrl: ${_dio!.options.baseUrl}');

      // Add interceptor for token
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            print('═══════════════════════════════════════════════════════');
            print('📡 StockOrderApi REQUEST (Interceptor)');
            print('   Method: ${options.method}');
            print('   Base URL: ${options.baseUrl}');
            print('   Path: ${options.path}');
            print('   Full URL: ${options.baseUrl}${options.path}');
            print('   Headers:');
            options.headers.forEach((key, value) {
              if (key == 'Authorization') {
                print('     $key: Bearer ${value.toString().substring(7, 27)}... (truncated)');
              } else {
                print('     $key: $value');
              }
            });
            if (options.data != null) {
              print('   Request Body: ${options.data}');
              print('   Request Body Type: ${options.data.runtimeType}');
              if (options.data is Map) {
                print('   Request Body (Map keys): ${(options.data as Map).keys.toList()}');
              }
            } else {
              print('   Request Body: null (no body)');
            }
            if (options.queryParameters.isNotEmpty) {
              print('   Query Parameters: ${options.queryParameters}');
            }
            print('═══════════════════════════════════════════════════════');
            return handler.next(options);
          },
          onResponse: (response, handler) {
            print('📥 StockOrderApi RESPONSE: ${response.statusCode}');
            return handler.next(response);
          },
          onError: (error, handler) {
            print('❌ StockOrderApi ERROR: ${error.message}');
            if (error.response != null) {
              print('   Status: ${error.response?.statusCode}');
              print('   Data: ${error.response?.data}');
            }
            return handler.next(error);
          },
        ),
      );
    }
    return _dio!;
  }

  /// Get list of stock orders with optional status filter
  static Future<List<StockOrderModel>> getStockOrders({String? status, int? forTechnicianId}) async {
    try {
      print('🚀 StockOrderApi: Fetching stock orders...');
      String endpoint = '/mobile/stock-orders';
      List<String> queryParams = [];
      
      if (status != null) {
        queryParams.add('status=$status');
      }
      //if (forTechnicianId != null) {
      //  queryParams.add('for_technician_id=$forTechnicianId');
      //}
      
      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }
      
      print('   Endpoint: $endpoint');
      print('   Full URL: ${dio.options.baseUrl}$endpoint');
      
      final response = await dio.get(
        endpoint,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      print('📥 StockOrderApi: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> ordersList = [];
        
        print('📦 StockOrderApi: Raw response data type: ${data.runtimeType}');
        print('📦 StockOrderApi: Raw response data: $data');
        
        if (data is Map) {
          // Handle format: { "success": true, "data": [...] }
          if (data['success'] == true && data['data'] != null) {
            final responseData = data['data'];
            print('📦 StockOrderApi: Found success=true, data type: ${responseData.runtimeType}');
            if (responseData is List) {
              ordersList = responseData;
              print('📦 StockOrderApi: Extracted ${ordersList.length} orders from data array');
            } else if (responseData is Map && responseData['data'] != null && responseData['data'] is List) {
              // Handle nested pagination: { "success": true, "data": { "data": [...] } }
              ordersList = responseData['data'] as List;
              print('📦 StockOrderApi: Extracted ${ordersList.length} orders from nested data');
            }
          } else if (data['data'] != null) {
            // Handle format: { "data": [...] }
            if (data['data'] is List) {
              ordersList = data['data'] as List;
              print('📦 StockOrderApi: Extracted ${ordersList.length} orders from data');
            } else if (data['data'] is Map && data['data']['data'] != null && data['data']['data'] is List) {
              ordersList = data['data']['data'] as List;
              print('📦 StockOrderApi: Extracted ${ordersList.length} orders from nested data');
            }
          }
        } else if (data is List) {
          // Handle direct array response: [...]
          ordersList = data;
          print('📦 StockOrderApi: Response is direct array with ${ordersList.length} orders');
        }
        
        if (ordersList.isNotEmpty) {
          final orders = <StockOrderModel>[];
          for (var item in ordersList) {
            try {
              if (item is Map) {
                // Safely convert all keys to String
                final itemMap = <String, dynamic>{};
                try {
                  item.forEach((key, value) {
                    itemMap[key.toString()] = value;
                  });
                  final order = StockOrderModel.fromJson(itemMap);
                  orders.add(order);
                } catch (e) {
                  print('❌ StockOrderApi: Error converting item map: $e');
                  print('   Item keys: ${item.keys}');
                  print('   Item: $item');
                  // Try direct conversion as fallback
                  try {
                    final order = StockOrderModel.fromJson(Map<String, dynamic>.from(item));
                    orders.add(order);
                  } catch (e2) {
                    print('❌ StockOrderApi: Fallback conversion also failed: $e2');
                    // Skip this item
                  }
                }
              }
            } catch (e, stackTrace) {
              print('❌ StockOrderApi: Error parsing order item: $e');
              print('   Item: $item');
              print('   Stack trace: $stackTrace');
              // Continue with next item instead of failing completely
            }
          }
          print('✅ StockOrderApi: Successfully parsed ${orders.length} stock orders');
          return orders;
        } else {
          print('⚠️ StockOrderApi: No stock orders found');
          return [];
        }
      } else {
        print('⚠️ StockOrderApi: Unexpected status code: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      print('❌ StockOrderApi: DioException: ${e.message}');
      print('   Type: ${e.type}');
      print('   Error: ${e.error}');
      
      if (e.type == DioExceptionType.connectionError) {
        final errorMsg = 'Network error: Unable to connect to server.\n\n'
            'Possible causes:\n'
            '1. The API server is not running\n'
            '2. CORS is not configured on the backend (if running on web)\n'
            '3. The URL ${dio.options.baseUrl} is not accessible\n'
            '4. Check your internet connection';
        throw Exception(errorMsg);
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout: The server took too long to respond.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Receive timeout: The server took too long to send data.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to view stock orders.');
      } else if (e.response?.statusCode == 404) {
        print('⚠️ StockOrderApi: Endpoint not found (404)');
        return [];
      } else if (e.response != null) {
        throw Exception('Failed to load stock orders: ${e.response?.statusCode} - ${e.message}');
      } else {
        throw Exception('Failed to load stock orders: ${e.message ?? e.type.toString()}');
      }
    } catch (e, stackTrace) {
      print('❌ StockOrderApi: Unexpected error: $e');
      print('❌ Stack trace: $stackTrace');
      if (e.toString().contains('XMLHttpRequest') || 
          e.toString().contains('connection') ||
          e.toString().contains('NetworkError')) {
        throw Exception('Network error: Unable to connect to the API server.\n\n'
            'If running on web, this is likely a CORS issue.\n'
            'Please ensure your Laravel backend has CORS configured to allow requests from your web origin.');
      }
      throw Exception('Failed to load stock orders: ${e.toString()}');
    }
  }

  /// Get stock order by ID
  static Future<StockOrderModel?> getStockOrderById(int id) async {
    try {
      print('🚀 StockOrderApi: Fetching stock order $id...');
      final response = await dio.get('/mobile/stock-orders/$id');
      
      print('📥 StockOrderApi: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> orderData;
        
        if (data is Map) {
          if (data['success'] == true && data['data'] != null) {
            final responseData = data['data'];
            if (responseData is Map && responseData['data'] != null) {
              orderData = responseData['data'] as Map<String, dynamic>;
            } else if (responseData is Map) {
              orderData = responseData as Map<String, dynamic>;
            } else {
              return null;
            }
          } else if (data['data'] != null && data['data'] is Map) {
            orderData = data['data'] as Map<String, dynamic>;
          } else {
            return null;
          }
        } else {
          return null;
        }
        
        print('✅ StockOrderApi: Successfully parsed stock order');
        return StockOrderModel.fromJson(orderData);
      } else if (response.statusCode == 404) {
        print('⚠️ StockOrderApi: Stock order not found (404)');
        return null;
      }
      return null;
    } on DioException catch (e) {
      print('❌ StockOrderApi: DioException: ${e.message}');
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to view this stock order.');
      } else if (e.response?.statusCode == 404) {
        return null;
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ StockOrderApi: Unexpected error: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Create stock order
  static Future<Map<String, dynamic>> createStockOrder(Map<String, dynamic> data) async {
    try {
      print('🚀 StockOrderApi: Creating stock order...');
      print('   Data: $data');
      final response = await dio.post('/mobile/stock-orders', data: data);
      
      print('📥 StockOrderApi: Response status: ${response.statusCode}');
      print('📥 StockOrderApi: Response data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map) {
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock order created successfully',
            'data': responseData['data'],
          };
        }
        return {
          'success': true,
          'message': 'Stock order created successfully',
        };
      }
      
      // Handle 422 validation errors
      if (response.statusCode == 422) {
        final responseData = response.data;
        String errorMessage = 'Validation failed';
        List<String> errorMessages = [];
        
        if (responseData is Map) {
          if (responseData['message'] != null) {
            errorMessage = responseData['message'].toString();
          }
          if (responseData['errors'] != null) {
            final errors = responseData['errors'];
            if (errors is Map) {
              errors.forEach((key, value) {
                if (value is List) {
                  for (var msg in value) {
                    errorMessages.add('$key: $msg');
                  }
                } else {
                  errorMessages.add('$key: $value');
                }
              });
            }
          }
        }
        
        final finalMessage = errorMessages.isNotEmpty 
            ? errorMessages.join('\n')
            : errorMessage;
        
        print('❌ StockOrderApi: Validation errors: $finalMessage');
        return {
          'success': false,
          'message': finalMessage,
          'errors': errorMessages,
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to create stock order',
      };
    } on DioException catch (e) {
      print('❌ StockOrderApi: DioException: ${e.message}');
      print('❌ StockOrderApi: Response: ${e.response?.data}');
      String errorMessage = 'Failed to create stock order';
      List<String> errorMessages = [];
      
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'You do not have permission to create stock orders.';
      } else if (e.response?.statusCode == 422) {
        // Handle validation errors
        if (e.response?.data != null) {
          final errorData = e.response!.data;
          if (errorData is Map) {
            if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            }
            if (errorData['errors'] != null) {
              final errors = errorData['errors'];
              if (errors is Map) {
                errors.forEach((key, value) {
                  if (value is List) {
                    for (var msg in value) {
                      errorMessages.add('$key: $msg');
                    }
                  } else {
                    errorMessages.add('$key: $value');
                  }
                });
              }
            }
          }
        }
        errorMessage = errorMessages.isNotEmpty 
            ? errorMessages.join('\n')
            : errorMessage;
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        } else if (errorData is Map && errorData['errors'] != null) {
          final errors = errorData['errors'] as Map;
          errorMessage = errors.values.first.toString().replaceAll('[', '').replaceAll(']', '');
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
        'errors': errorMessages,
      };
    } catch (e) {
      print('❌ StockOrderApi: Unexpected error: $e');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Approve stock order by Team Leader
  static Future<Map<String, dynamic>> approveByTeamLeader(int id, {String? remarks}) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🚀 StockOrderApi: Approving stock order $id by Team Leader');
      print('   Endpoint: /stock-orders/$id/approve-tl');
      print('   Full URL: ${dio.options.baseUrl}/stock-orders/$id/approve-tl');
      print('   Method: POST');
      
      // Get token for logging
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        print('   Token: ${token.substring(0, 20)}... (truncated)');
      } else {
        print('   ⚠️ No auth token found!');
      }
      
      // Prepare request data with remarks if available
      final requestData = <String, dynamic>{};
      if (remarks != null && remarks.trim().isNotEmpty) {
        requestData['remarks'] = remarks.trim();
        print('   Remarks: ${remarks.trim()}');
      }
      print('   Request Body: $requestData');
      print('   Request Body Type: ${requestData.runtimeType}');
      print('   Request Body (JSON): ${requestData.isEmpty ? "{}" : requestData}');
      
      final response = await dio.post(
        '/stock-orders/$id/approve-tl',
        data: requestData,
      );
      
      print('═══════════════════════════════════════════════════════');
      print('📥 StockOrderApi: Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Status Message: ${response.statusMessage}');
      print('   Response Type: ${response.data.runtimeType}');
      print('   Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('   ✅ Success response (${response.statusCode})');
        
        if (responseData is Map) {
          print('   Response is Map');
          print('   Message: ${responseData['message']}');
          print('   Data: ${responseData['data']}');
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock order approved successfully',
            'data': responseData['data'],
          };
        } else {
          print('   Response is not Map, type: ${responseData.runtimeType}');
        }
        return {
          'success': true,
          'message': 'Stock order approved successfully',
        };
      } else {
        print('   ⚠️ Unexpected status code: ${response.statusCode}');
      }
      
      return {
        'success': false,
        'message': 'Failed to approve stock order',
      };
    } on DioException catch (e) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: DioException in approveByTeamLeader');
      print('   Exception Type: ${e.type}');
      print('   Error Message: ${e.message}');
      print('   Error: ${e.error}');
      
      if (e.response != null) {
        print('   Response Status: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Response Headers: ${e.response?.headers}');
      } else {
        print('   ⚠️ No response data available');
      }
      
      String errorMessage = 'Failed to approve stock order';
      
      if (e.response?.statusCode == 401) {
        print('   🔒 Unauthorized (401)');
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
      } else if (e.response?.statusCode == 403) {
        print('   🚫 Forbidden (403)');
        errorMessage = 'You do not have permission to approve this stock order.';
      } else if (e.response?.statusCode == 404) {
        print('   🔍 Not Found (404)');
        errorMessage = 'Stock order or endpoint not found.';
      } else if (e.response?.statusCode == 422) {
        print('   ⚠️ Validation Error (422)');
        errorMessage = 'Validation failed. Please check the order status.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        print('   Error Data Type: ${errorData.runtimeType}');
        if (errorData is Map) {
          print('   Error Data: $errorData');
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
            print('   Extracted Error Message: $errorMessage');
          }
          if (errorData['errors'] != null) {
            print('   Validation Errors: ${errorData['errors']}');
          }
        } else {
          print('   Error Data (non-Map): $errorData');
        }
      }
      
      print('   Final Error Message: $errorMessage');
      print('═══════════════════════════════════════════════════════');
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: Unexpected error in approveByTeamLeader');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Reject stock order by Team Leader
  static Future<Map<String, dynamic>> rejectByTeamLeader(int id, {String? reason}) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🚀 StockOrderApi: Rejecting stock order $id by Team Leader');
      print('   Endpoint: /stock-orders/$id/reject');
      print('   Full URL: ${dio.options.baseUrl}/stock-orders/$id/reject');
      print('   Method: POST');
      
      // Get token for logging
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        print('   Token: ${token.substring(0, 20)}... (truncated)');
      } else {
        print('   ⚠️ No auth token found!');
      }
      
      // Prepare request data with reason if available
      final requestData = reason != null && reason.trim().isNotEmpty 
          ? {'reason': reason.trim()} 
          : <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        print('   Reason: ${reason.trim()}');
      }
      print('   Request Body: $requestData');
      print('   Request Body Type: ${requestData.runtimeType}');
      print('   Request Body (JSON): ${requestData.isEmpty ? "{}" : requestData}');
      
      final response = await dio.post(
        '/stock-orders/$id/reject',
        data: requestData,  // Always send an object, even if empty
      );
      
      print('═══════════════════════════════════════════════════════');
      print('📥 StockOrderApi: Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Status Message: ${response.statusMessage}');
      print('   Response Type: ${response.data.runtimeType}');
      print('   Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('   ✅ Success response (${response.statusCode})');
        
        if (responseData is Map) {
          print('   Response is Map');
          print('   Message: ${responseData['message']}');
          print('   Data: ${responseData['data']}');
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock order rejected successfully',
            'data': responseData['data'],
          };
        } else {
          print('   Response is not Map, type: ${responseData.runtimeType}');
        }
        return {
          'success': true,
          'message': 'Stock order rejected successfully',
        };
      } else {
        print('   ⚠️ Unexpected status code: ${response.statusCode}');
      }
      
      return {
        'success': false,
        'message': 'Failed to reject stock order',
      };
    } on DioException catch (e) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: DioException in rejectByTeamLeader');
      print('   Exception Type: ${e.type}');
      print('   Error Message: ${e.message}');
      print('   Error: ${e.error}');
      
      if (e.response != null) {
        print('   Response Status: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Response Headers: ${e.response?.headers}');
      } else {
        print('   ⚠️ No response data available');
      }
      
      String errorMessage = 'Failed to reject stock order';
      
      if (e.response?.statusCode == 401) {
        print('   🔒 Unauthorized (401)');
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
      } else if (e.response?.statusCode == 403) {
        print('   🚫 Forbidden (403)');
        errorMessage = 'You do not have permission to reject this stock order.';
      } else if (e.response?.statusCode == 404) {
        print('   🔍 Not Found (404)');
        errorMessage = 'Stock order or endpoint not found.';
      } else if (e.response?.statusCode == 422) {
        print('   ⚠️ Validation Error (422)');
        errorMessage = 'Validation failed. Please check the order status.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        print('   Error Data Type: ${errorData.runtimeType}');
        if (errorData is Map) {
          print('   Error Data: $errorData');
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
            print('   Extracted Error Message: $errorMessage');
          }
          if (errorData['errors'] != null) {
            print('   Validation Errors: ${errorData['errors']}');
          }
        } else {
          print('   Error Data (non-Map): $errorData');
        }
      }
      
      print('   Final Error Message: $errorMessage');
      print('═══════════════════════════════════════════════════════');
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: Unexpected error in rejectByTeamLeader');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Approve stock order by Manager
  static Future<Map<String, dynamic>> approveByManager(int id, {String? remarks}) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🚀 StockOrderApi: Approving stock order $id by Manager');
      print('   Endpoint: /stock-orders/$id/approve-manager');
      print('   Full URL: ${dio.options.baseUrl}/stock-orders/$id/approve-manager');
      print('   Method: POST');
      
      // Get token for logging
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        print('   Token: ${token.substring(0, 20)}... (truncated)');
      } else {
        print('   ⚠️ No auth token found!');
      }
      
      // Prepare request data with remarks if available
      final requestData = <String, dynamic>{};
      if (remarks != null && remarks.trim().isNotEmpty) {
        requestData['remarks'] = remarks.trim();
        print('   Remarks: ${remarks.trim()}');
      }
      print('   Request Body: $requestData');
      print('   Request Body Type: ${requestData.runtimeType}');
      print('   Request Body (JSON): ${requestData.isEmpty ? "{}" : requestData}');
      
      final response = await dio.post(
        '/stock-orders/$id/approve-manager',
        data: requestData,
      );
      
      print('═══════════════════════════════════════════════════════');
      print('📥 StockOrderApi: Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Status Message: ${response.statusMessage}');
      print('   Response Type: ${response.data.runtimeType}');
      print('   Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('   ✅ Success response (${response.statusCode})');
        
        if (responseData is Map) {
          print('   Response is Map');
          print('   Message: ${responseData['message']}');
          print('   Data: ${responseData['data']}');
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock order approved successfully',
            'data': responseData['data'],
          };
        } else {
          print('   Response is not Map, type: ${responseData.runtimeType}');
        }
        return {
          'success': true,
          'message': 'Stock order approved successfully',
        };
      } else {
        print('   ⚠️ Unexpected status code: ${response.statusCode}');
      }
      
      return {
        'success': false,
        'message': 'Failed to approve stock order',
      };
    } on DioException catch (e) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: DioException in approveByManager');
      print('   Exception Type: ${e.type}');
      print('   Error Message: ${e.message}');
      print('   Error: ${e.error}');
      
      if (e.response != null) {
        print('   Response Status: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Response Headers: ${e.response?.headers}');
      } else {
        print('   ⚠️ No response data available');
      }
      
      String errorMessage = 'Failed to approve stock order';
      
      if (e.response?.statusCode == 401) {
        print('   🔒 Unauthorized (401)');
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
      } else if (e.response?.statusCode == 403) {
        print('   🚫 Forbidden (403)');
        errorMessage = 'You do not have permission to approve this stock order.';
      } else if (e.response?.statusCode == 404) {
        print('   🔍 Not Found (404)');
        errorMessage = 'Stock order or endpoint not found.';
      } else if (e.response?.statusCode == 422) {
        print('   ⚠️ Validation Error (422)');
        errorMessage = 'Validation failed. Please check the order status.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        print('   Error Data Type: ${errorData.runtimeType}');
        if (errorData is Map) {
          print('   Error Data: $errorData');
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
            print('   Extracted Error Message: $errorMessage');
          }
          if (errorData['errors'] != null) {
            print('   Validation Errors: ${errorData['errors']}');
          }
        } else {
          print('   Error Data (non-Map): $errorData');
        }
      }
      
      print('   Final Error Message: $errorMessage');
      print('═══════════════════════════════════════════════════════');
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: Unexpected error in approveByManager');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Reject stock order by Manager
  static Future<Map<String, dynamic>> rejectByManager(int id, {String? reason}) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🚀 StockOrderApi: Rejecting stock order $id by Manager');
      print('   Endpoint: /stock-orders/$id/reject');
      print('   Full URL: ${dio.options.baseUrl}/stock-orders/$id/reject');
      print('   Method: POST');
      
      // Get token for logging
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        print('   Token: ${token.substring(0, 20)}... (truncated)');
      } else {
        print('   ⚠️ No auth token found!');
      }
      
      // Prepare request data with reason if available
      final requestData = reason != null && reason.trim().isNotEmpty 
          ? {'reason': reason.trim()} 
          : <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        print('   Reason: ${reason.trim()}');
      }
      print('   Request Body: $requestData');
      print('   Request Body Type: ${requestData.runtimeType}');
      print('   Request Body (JSON): ${requestData.isEmpty ? "{}" : requestData}');
      
      final response = await dio.post(
        '/stock-orders/$id/reject',
        data: requestData,  // Always send an object, even if empty
      );
      
      print('═══════════════════════════════════════════════════════');
      print('📥 StockOrderApi: Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Status Message: ${response.statusMessage}');
      print('   Response Type: ${response.data.runtimeType}');
      print('   Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('   ✅ Success response (${response.statusCode})');
        
        if (responseData is Map) {
          print('   Response is Map');
          print('   Message: ${responseData['message']}');
          print('   Data: ${responseData['data']}');
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock order rejected successfully',
            'data': responseData['data'],
          };
        } else {
          print('   Response is not Map, type: ${responseData.runtimeType}');
        }
        return {
          'success': true,
          'message': 'Stock order rejected successfully',
        };
      } else {
        print('   ⚠️ Unexpected status code: ${response.statusCode}');
      }
      
      return {
        'success': false,
        'message': 'Failed to reject stock order',
      };
    } on DioException catch (e) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: DioException in rejectByManager');
      print('   Exception Type: ${e.type}');
      print('   Error Message: ${e.message}');
      print('   Error: ${e.error}');
      
      if (e.response != null) {
        print('   Response Status: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Response Headers: ${e.response?.headers}');
      } else {
        print('   ⚠️ No response data available');
      }
      
      String errorMessage = 'Failed to reject stock order';
      
      if (e.response?.statusCode == 401) {
        print('   🔒 Unauthorized (401)');
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
      } else if (e.response?.statusCode == 403) {
        print('   🚫 Forbidden (403)');
        errorMessage = 'You do not have permission to reject this stock order.';
      } else if (e.response?.statusCode == 404) {
        print('   🔍 Not Found (404)');
        errorMessage = 'Stock order or endpoint not found.';
      } else if (e.response?.statusCode == 422) {
        print('   ⚠️ Validation Error (422)');
        errorMessage = 'Validation failed. Please check the order status.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        print('   Error Data Type: ${errorData.runtimeType}');
        if (errorData is Map) {
          print('   Error Data: $errorData');
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
            print('   Extracted Error Message: $errorMessage');
          }
          if (errorData['errors'] != null) {
            print('   Validation Errors: ${errorData['errors']}');
          }
        } else {
          print('   Error Data (non-Map): $errorData');
        }
      }
      
      print('   Final Error Message: $errorMessage');
      print('═══════════════════════════════════════════════════════');
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: Unexpected error in rejectByManager');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Issue stock order by Store Keeper
  static Future<Map<String, dynamic>> issueStock(int id) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🚀 StockOrderApi: Issuing stock order $id by Store Keeper');
      print('   Endpoint: /stock-orders/$id/issue');
      print('   Full URL: ${dio.options.baseUrl}/stock-orders/$id/issue');
      print('   Method: POST');
      
      // Get token for logging
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        print('   Token: ${token.substring(0, 20)}... (truncated)');
      } else {
        print('   ⚠️ No auth token found!');
      }
      
      // Prepare request data (empty body for issue)
      final requestData = <String, dynamic>{};
      print('   Request Body: $requestData');
      print('   Request Body Type: ${requestData.runtimeType}');
      print('   Request Body (JSON): ${requestData.isEmpty ? "{}" : requestData}');
      
      final response = await dio.post(
        '/stock-orders/$id/issue',
        data: requestData,
      );
      
      print('═══════════════════════════════════════════════════════');
      print('📥 StockOrderApi: Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Status Message: ${response.statusMessage}');
      print('   Response Type: ${response.data.runtimeType}');
      print('   Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('   ✅ Success response (${response.statusCode})');
        
        if (responseData is Map) {
          print('   Response is Map');
          print('   Message: ${responseData['message']}');
          print('   Data: ${responseData['data']}');
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock issued successfully',
            'data': responseData['data'],
          };
        } else {
          print('   Response is not Map, type: ${responseData.runtimeType}');
        }
        return {
          'success': true,
          'message': 'Stock issued successfully',
        };
      } else {
        print('   ⚠️ Unexpected status code: ${response.statusCode}');
      }
      
      return {
        'success': false,
        'message': 'Failed to issue stock',
      };
    } on DioException catch (e) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: DioException in issueStock');
      print('   Exception Type: ${e.type}');
      print('   Error Message: ${e.message}');
      print('   Error: ${e.error}');
      
      if (e.response != null) {
        print('   Response Status: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Response Headers: ${e.response?.headers}');
      } else {
        print('   ⚠️ No response data available');
      }
      
      String errorMessage = 'Failed to issue stock';
      
      if (e.response?.statusCode == 401) {
        print('   🔒 Unauthorized (401)');
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
      } else if (e.response?.statusCode == 403) {
        print('   🚫 Forbidden (403)');
        errorMessage = 'You do not have permission to issue this stock order.';
      } else if (e.response?.statusCode == 404) {
        print('   🔍 Not Found (404)');
        errorMessage = 'Stock order or endpoint not found.';
      } else if (e.response?.statusCode == 422) {
        print('   ⚠️ Validation Error (422)');
        errorMessage = 'Validation failed. Please check the order status.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        print('   Error Data Type: ${errorData.runtimeType}');
        if (errorData is Map) {
          print('   Error Data: $errorData');
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
            print('   Extracted Error Message: $errorMessage');
          }
          if (errorData['errors'] != null) {
            print('   Validation Errors: ${errorData['errors']}');
          }
        } else {
          print('   Error Data (non-Map): $errorData');
        }
      }
      
      print('   Final Error Message: $errorMessage');
      print('═══════════════════════════════════════════════════════');
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: Unexpected error in issueStock');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }

  /// Accept stock order by Technician
  static Future<Map<String, dynamic>> acceptStock(int id) async {
    try {
      print('🚀 StockOrderApi: Accepting stock order $id...');
      final response = await dio.post('/mobile/stock-orders/$id/accept');
      
      print('📥 StockOrderApi: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map) {
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock accepted successfully',
          };
        }
        return {
          'success': true,
          'message': 'Stock accepted successfully',
        };
      }
      
      return {
        'success': false,
        'message': 'Failed to accept stock',
      };
    } on DioException catch (e) {
      print('❌ StockOrderApi: DioException: ${e.message}');
      String errorMessage = 'Failed to accept stock';
      
      if (e.response?.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
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

  /// Reject stock order by Technician
  static Future<Map<String, dynamic>> rejectStock(int id, {String? reason}) async {
    try {
      print('═══════════════════════════════════════════════════════');
      print('🚀 StockOrderApi: Rejecting stock order $id by Technician');
      print('   Endpoint: /stock-orders/$id/reject');
      print('   Full URL: ${dio.options.baseUrl}/stock-orders/$id/reject');
      print('   Method: POST');
      
      // Get token for logging
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        print('   Token: ${token.substring(0, 20)}... (truncated)');
      } else {
        print('   ⚠️ No auth token found!');
      }
      
      // Prepare request data with reason if available
      final requestData = reason != null && reason.trim().isNotEmpty 
          ? {'reason': reason.trim()} 
          : <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        print('   Reason: ${reason.trim()}');
      }
      print('   Request Body: $requestData');
      print('   Request Body Type: ${requestData.runtimeType}');
      print('   Request Body (JSON): ${requestData.isEmpty ? "{}" : requestData}');
      
      final response = await dio.post(
        '/stock-orders/$id/reject',
        data: requestData,  // Always send an object, even if empty
      );
      
      print('═══════════════════════════════════════════════════════');
      print('📥 StockOrderApi: Response received');
      print('   Status Code: ${response.statusCode}');
      print('   Status Message: ${response.statusMessage}');
      print('   Response Type: ${response.data.runtimeType}');
      print('   Response Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        print('   ✅ Success response (${response.statusCode})');
        
        if (responseData is Map) {
          print('   Response is Map');
          print('   Message: ${responseData['message']}');
          print('   Data: ${responseData['data']}');
          return {
            'success': true,
            'message': responseData['message']?.toString() ?? 'Stock order rejected successfully',
            'data': responseData['data'],
          };
        } else {
          print('   Response is not Map, type: ${responseData.runtimeType}');
        }
        return {
          'success': true,
          'message': 'Stock order rejected successfully',
        };
      } else {
        print('   ⚠️ Unexpected status code: ${response.statusCode}');
      }
      
      return {
        'success': false,
        'message': 'Failed to reject stock order',
      };
    } on DioException catch (e) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: DioException in rejectStock');
      print('   Exception Type: ${e.type}');
      print('   Error Message: ${e.message}');
      print('   Error: ${e.error}');
      
      if (e.response != null) {
        print('   Response Status: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Response Headers: ${e.response?.headers}');
      } else {
        print('   ⚠️ No response data available');
      }
      
      String errorMessage = 'Failed to reject stock order';
      
      if (e.response?.statusCode == 401) {
        print('   🔒 Unauthorized (401)');
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
          'unauthorized': true,
        };
      } else if (e.response?.statusCode == 403) {
        print('   🚫 Forbidden (403)');
        errorMessage = 'You do not have permission to reject this stock order.';
      } else if (e.response?.statusCode == 404) {
        print('   🔍 Not Found (404)');
        errorMessage = 'Stock order or endpoint not found.';
      } else if (e.response?.statusCode == 422) {
        print('   ⚠️ Validation Error (422)');
        errorMessage = 'Validation failed. Please check the order status.';
      } else if (e.response?.data != null) {
        final errorData = e.response!.data;
        print('   Error Data Type: ${errorData.runtimeType}');
        if (errorData is Map) {
          print('   Error Data: $errorData');
          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
            print('   Extracted Error Message: $errorMessage');
          }
          if (errorData['errors'] != null) {
            print('   Validation Errors: ${errorData['errors']}');
          }
        } else {
          print('   Error Data (non-Map): $errorData');
        }
      }
      
      print('   Final Error Message: $errorMessage');
      print('═══════════════════════════════════════════════════════');
      
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════════════════════');
      print('❌ StockOrderApi: Unexpected error in rejectStock');
      print('   Error: $e');
      print('   Error Type: ${e.runtimeType}');
      print('   Stack Trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      return {
        'success': false,
        'message': 'Unexpected error: ${e.toString()}',
      };
    }
  }
}

