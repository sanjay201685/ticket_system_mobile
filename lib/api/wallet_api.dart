import 'dart:convert';
import '../api/api_client.dart';
import '../models/wallet_transaction_model.dart';

class WalletApi {
  /// Get transaction history
  /// 
  /// [userId] - User ID (optional, defaults to authenticated user)
  /// [type] - Filter by type: 'credit' or 'debit'
  /// [status] - Filter by status: 'pending', 'paid', or 'failed'
  /// [limit] - Number of records to return (default: 50, max: 50)
  static Future<List<WalletTransaction>> getTransactions({
    int? userId,
    String? type,
    String? status,
    int? limit,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      // Build endpoint with query parameters
      String endpoint = '/wallet/transaction';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        endpoint = '$endpoint?$queryString';
      }

      print('📡 WalletApi.getTransactions: $endpoint');

      final response = await ApiClient.get(endpoint);
      final result = ApiClient.handleResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          return data
              .map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data is Map && data.containsKey('data') && data['data'] is List) {
          // Handle nested data structure
          return (data['data'] as List)
              .map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception('Invalid response format: expected list of transactions');
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch transactions');
      }
    } catch (e) {
      print('❌ WalletApi.getTransactions error: $e');
      rethrow;
    }
  }

  /// Create a new wallet transaction
  /// 
  /// [userId] - User ID (required)
  /// [transactionType] - 'credit' or 'debit'
  /// [amount] - Amount (min: 0.01)
  /// [referenceType] - Reference type (e.g., 'manual', 'purchase_request', 'refund')
  /// [referenceId] - Reference ID (e.g., purchase request ID)
  /// [notes] - Additional notes
  static Future<Map<String, dynamic>> createTransaction({
    required int userId,
    required String transactionType,
    required double amount,
    String? referenceType,
    int? referenceId,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'user_id': userId,
        'transaction_type': transactionType,
        'amount': amount,
      };

      if (referenceType != null && referenceType.isNotEmpty) {
        body['reference_type'] = referenceType;
      }
      if (referenceId != null) {
        body['reference_id'] = referenceId;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      print('📡 WalletApi.createTransaction: POST /wallet/transaction');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await ApiClient.post('/wallet/transaction', body);
      final result = ApiClient.handleResponse(response);

      if (result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'Transaction created successfully',
          'data': result['data'],
        };
      } else {
        // Handle validation errors
        if (result.containsKey('errors')) {
          return {
            'success': false,
            'message': result['message'] ?? 'Validation failed',
            'errors': result['errors'],
          };
        }
        throw Exception(result['message'] ?? 'Failed to create transaction');
      }
    } catch (e) {
      print('❌ WalletApi.createTransaction error: $e');
      rethrow;
    }
  }

  /// Get wallet balance for a user
  /// 
  /// [userId] - User ID
  static Future<WalletBalance> getWalletBalance(int userId) async {
    try {
      print('📡 WalletApi.getWalletBalance: GET /wallet/$userId');

      final response = await ApiClient.get('/wallet/$userId');
      final result = ApiClient.handleResponse(response);

      if (result['success'] == true) {
        final data = result['data'];
        if (data is Map) {
          return WalletBalance.fromJson(data as Map<String, dynamic>);
        } else {
          throw Exception('Invalid response format: expected wallet balance object');
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to fetch wallet balance');
      }
    } catch (e) {
      print('❌ WalletApi.getWalletBalance error: $e');
      rethrow;
    }
  }

  /// Debit wallet (alternative endpoint)
  /// 
  /// [userId] - User ID
  /// [amount] - Amount to debit
  /// [referenceType] - Reference type
  /// [notes] - Additional notes
  static Future<Map<String, dynamic>> debitWallet({
    required int userId,
    required double amount,
    String? referenceType,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
      };

      if (referenceType != null && referenceType.isNotEmpty) {
        body['reference_type'] = referenceType;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      print('📡 WalletApi.debitWallet: POST /wallets/$userId/debit');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await ApiClient.post('/wallets/$userId/debit', body);
      final result = ApiClient.handleResponse(response);

      if (result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'Wallet debited successfully',
          'data': result['data'],
        };
      } else {
        if (result.containsKey('errors')) {
          return {
            'success': false,
            'message': result['message'] ?? 'Validation failed',
            'errors': result['errors'],
          };
        }
        throw Exception(result['message'] ?? 'Failed to debit wallet');
      }
    } catch (e) {
      print('❌ WalletApi.debitWallet error: $e');
      rethrow;
    }
  }

  /// Credit wallet (alternative endpoint)
  /// 
  /// [userId] - User ID
  /// [amount] - Amount to credit
  /// [referenceType] - Reference type
  /// [notes] - Additional notes
  static Future<Map<String, dynamic>> creditWallet({
    required int userId,
    required double amount,
    String? referenceType,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'amount': amount,
      };

      if (referenceType != null && referenceType.isNotEmpty) {
        body['reference_type'] = referenceType;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }

      print('📡 WalletApi.creditWallet: POST /wallets/$userId/credit');
      print('📤 Body: ${jsonEncode(body)}');

      final response = await ApiClient.post('/wallets/$userId/credit', body);
      final result = ApiClient.handleResponse(response);

      if (result['success'] == true) {
        return {
          'success': true,
          'message': result['message'] ?? 'Wallet credited successfully',
          'data': result['data'],
        };
      } else {
        if (result.containsKey('errors')) {
          return {
            'success': false,
            'message': result['message'] ?? 'Validation failed',
            'errors': result['errors'],
          };
        }
        throw Exception(result['message'] ?? 'Failed to credit wallet');
      }
    } catch (e) {
      print('❌ WalletApi.creditWallet error: $e');
      rethrow;
    }
  }
}
