import '../api/api_client.dart';
import '../models/order_model.dart';

class OrderApi {
  // Get all orders
  static Future<List<OrderModel>> getOrders({
    String? status,
    String? vendorType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    String endpoint = '/orders';
    List<String> queryParams = [];
    
    if (status != null && status.isNotEmpty) {
      queryParams.add('status=$status');
    }
    if (vendorType != null && vendorType.isNotEmpty) {
      queryParams.add('vendor_type=$vendorType');
    }
    if (fromDate != null) {
      queryParams.add('from_date=${fromDate.toIso8601String().split('T')[0]}');
    }
    if (toDate != null) {
      queryParams.add('to_date=${toDate.toIso8601String().split('T')[0]}');
    }
    
    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }
    
    final result = await ApiClient.get(endpoint);
    if (result['success'] == true) {
      final data = result['data'];
      if (data is List) {
        return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
      } else if (data is Map && data['data'] is List) {
        return (data['data'] as List)
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  // Get single order by ID
  static Future<OrderModel?> getOrderById(int orderId) async {
    final result = await ApiClient.get('/orders/$orderId');
    if (result['success'] == true) {
      final data = result['data'];
      if (data is Map) {
        return OrderModel.fromJson(data as Map<String, dynamic>);
      }
    }
    return null;
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(
    int orderId,
    String status,
  ) async {
    return await ApiClient.post(
      '/orders/$orderId/status',
      {'status': status},
    );
  }

  // Delete order
  static Future<Map<String, dynamic>> deleteOrder(int orderId) async {
    return await ApiClient.post(
      '/orders/$orderId/delete',
      {},
    );
  }
}

