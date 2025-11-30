import 'api_client.dart';
import 'dart:convert';
import '../models/purchase_request_model.dart';

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

  /// Get purchase request by ID (accessible to all roles)
  static Future<PurchaseRequestModel?> getPurchaseRequestById(int id) async {
    try {
      print('📡 PurchaseApi: Fetching purchase request $id...');
      final response = await ApiClient.get('/purchase-requests/$id');
      print('📥 PurchaseApi: Response status: ${response.statusCode}');
      
      final result = ApiClient.handleResponse(response);
      print('📥 PurchaseApi: Result success: ${result['success']}');
      
      if (result['success'] == true) {
        final data = result['data'];
        Map<String, dynamic> requestData;
        
        if (data is Map && data['data'] is Map) {
          requestData = data['data'] as Map<String, dynamic>;
        } else if (data is Map) {
          requestData = data as Map<String, dynamic>;
        } else {
          print('⚠️ PurchaseApi: Data is not a Map');
          return null;
        }
        
        print('✅ PurchaseApi: Successfully parsed purchase request');
        return PurchaseRequestModel.fromJson(requestData);
      } else {
        print('⚠️ PurchaseApi: API returned success=false: ${result['message']}');
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ PurchaseApi: Error getting purchase request: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get purchase requests for current user (technician's own requests)
  static Future<List<PurchaseRequestModel>> getMyPurchaseRequests() async {
    try {
      final response = await ApiClient.get('/purchase-requests');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        List<dynamic> requestsList = [];
        
        if (data is Map && data['data'] is List) {
          requestsList = data['data'] as List;
        } else if (data is List) {
          requestsList = data;
        }
        
        return requestsList
            .map((json) => PurchaseRequestModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting my purchase requests: $e');
      return [];
    }
  }
}



