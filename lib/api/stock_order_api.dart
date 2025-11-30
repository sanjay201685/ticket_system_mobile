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
            print('📡 StockOrderApi REQUEST: ${options.method} ${options.baseUrl}${options.path}');
            if (options.data != null) {
              print('   Body: ${options.data}');
            }
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

  /// Get list of stock orders
  static Future<List<StockOrderModel>> getStockOrders() async {
    try {
      print('🚀 StockOrderApi: Fetching stock orders...');
      final response = await dio.get('/mobile/stock-orders');
      
      print('📥 StockOrderApi: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> ordersList = [];
        
        if (data is Map) {
          if (data['success'] == true && data['data'] != null) {
            final responseData = data['data'];
            if (responseData is Map && responseData['data'] != null) {
              if (responseData['data'] is List) {
                ordersList = responseData['data'] as List;
              }
            } else if (responseData is List) {
              ordersList = responseData;
            }
          } else if (data['data'] != null) {
            if (data['data'] is List) {
              ordersList = data['data'] as List;
            } else if (data['data'] is Map && data['data']['data'] != null && data['data']['data'] is List) {
              ordersList = data['data']['data'] as List;
            }
          }
        } else if (data is List) {
          ordersList = data;
        }
        
        if (ordersList.isNotEmpty) {
          final orders = <StockOrderModel>[];
          for (var item in ordersList) {
            try {
              if (item is Map) {
                // Convert all keys to String to ensure proper type
                final itemMap = Map<String, dynamic>.from(item);
                final order = StockOrderModel.fromJson(itemMap);
                orders.add(order);
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
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('You do not have permission to view stock orders.');
      } else if (e.response?.statusCode == 404) {
        print('⚠️ StockOrderApi: Endpoint not found (404)');
        return [];
      }
      throw Exception('Failed to load stock orders: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ StockOrderApi: Unexpected error: $e');
      print('❌ Stack trace: $stackTrace');
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
        errorMessage = 'Unauthorized. Please login again.';
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
}

