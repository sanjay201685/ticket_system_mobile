import 'api_client.dart';
import 'dart:convert';

class PurchaseApi {
  /// Create purchase request
  static Future<Map<String, dynamic>> createPurchaseRequest(
    Map<String, dynamic> data,
  ) async {
    try {
      // print("Post value purchase-requests: " . (data));
      print('Post value purchase-requests:: ${data}');
      final response = await ApiClient.post('/purchase-requests/create', data);
      return ApiClient.handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}



