import 'package:flutter/foundation.dart';
import '../api/team_leader_api.dart';
import '../models/purchase_request_model.dart';

class TeamLeaderProvider with ChangeNotifier {
  List<PurchaseRequestModel> _purchaseRequests = [];
  PurchaseRequestModel? _selectedRequest;
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false; // Track if initial load has been attempted

  // Getters
  List<PurchaseRequestModel> get purchaseRequests => _purchaseRequests;
  PurchaseRequestModel? get selectedRequest => _selectedRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get pending count
  int get pendingCount {
    return _purchaseRequests.where((req) => 
      req.status?.toLowerCase() == 'pending' || 
      req.status == null
    ).length;
  }

  /// Load purchase requests list
  Future<void> loadPurchaseRequests({bool forceReload = false}) async {
    // Prevent multiple simultaneous loads
    if (_isLoading && !forceReload) {
      print('⚠️ TeamLeaderProvider: Already loading, skipping duplicate call...');
      return;
    }
    
    // If already initialized with data and not forcing reload, skip
    if (!forceReload && _hasInitialized && _purchaseRequests.isNotEmpty) {
      print('⚠️ TeamLeaderProvider: Already initialized with data, skipping...');
      return;
    }
    
    print('🔄 TeamLeaderProvider.loadPurchaseRequests() - Starting...');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📞 TeamLeaderProvider: Calling TeamLeaderApi.getPurchaseRequests()...');
      _purchaseRequests = await TeamLeaderApi.getPurchaseRequests();
      
      print('📦 TeamLeaderProvider: Received ${_purchaseRequests.length} purchase requests');
      
      _hasInitialized = true; // Mark as initialized
      
      // If no requests found and it might be a 404, show helpful message
      if (_purchaseRequests.isEmpty) {
        print('⚠️ TeamLeaderProvider: No purchase requests returned');
        _error = 'No purchase requests found.';
      } else {
        print('✅ TeamLeaderProvider: Successfully loaded ${_purchaseRequests.length} purchase requests');
        _error = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ TeamLeaderProvider.loadPurchaseRequests() ERROR:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      
      _hasInitialized = true; // Mark as initialized even on error to prevent retry loop
      _isLoading = false;
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _error = 'Unauthorized. Please login again.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        _error = 'You do not have permission to view purchase requests.';
      } else if (e.toString().contains('404')) {
        _error = 'Team leader endpoint not found. Please verify the API endpoint is configured correctly.';
      } else {
        _error = 'Failed to load purchase requests: ${e.toString()}';
      }
      notifyListeners();
    }
  }

  /// Load single purchase request by ID
  Future<void> loadPurchaseRequestById(int id, {bool forceReload = false}) async {
    // If forcing reload, clear the selected request first
    if (forceReload) {
      _selectedRequest = null;
    }
    
    // Prevent reloading if already loading or if same request is already loaded
    if (!forceReload && _isLoading) return;
    if (!forceReload && _selectedRequest != null && _selectedRequest!.id == id) {
      print('⚠️ TeamLeaderProvider: Request $id already loaded, skipping...');
      return; // Already loaded
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedRequest = await TeamLeaderApi.getPurchaseRequestById(id);
      _isLoading = false;
      if (_selectedRequest == null) {
        _error = 'Purchase request not found';
      } else {
        _error = null;
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _error = 'Unauthorized. Please login again.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        _error = 'You do not have permission to view this purchase request.';
      } else {
        _error = 'Failed to load purchase request: ${e.toString()}';
      }
      notifyListeners();
    }
  }

  /// Approve purchase request
  Future<Map<String, dynamic>> approvePurchaseRequest(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await TeamLeaderApi.approvePurchaseRequest(id);
      _isLoading = false;
      
      if (result['success'] == true) {
        // Reload the list
        await loadPurchaseRequests(forceReload: true);
        // Reload the selected request if it's the same one
        if (_selectedRequest?.id == id) {
          await loadPurchaseRequestById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to approve purchase request';
        notifyListeners();
        return result;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error: ${e.toString()}';
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    }
  }

  /// Reject purchase request
  Future<Map<String, dynamic>> rejectPurchaseRequest(
    int id,
    String reason,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await TeamLeaderApi.rejectPurchaseRequest(id, reason);
      _isLoading = false;
      
      if (result['success'] == true) {
        // Reload the list
        await loadPurchaseRequests(forceReload: true);
        // Reload the selected request if it's the same one
        if (_selectedRequest?.id == id) {
          await loadPurchaseRequestById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to reject purchase request';
        notifyListeners();
        return result;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Error: ${e.toString()}';
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear cache and reset initialization flag
  /// Use this when you want to force a fresh load next time
  void clearCache() {
    _hasInitialized = false;
    _purchaseRequests = [];
    _selectedRequest = null;
    _error = null;
    notifyListeners();
  }
}

