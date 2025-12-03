import 'package:flutter/foundation.dart';
import '../api/stock_order_api.dart';
import '../models/stock_order_model.dart';

class StockOrderProvider with ChangeNotifier {
  List<StockOrderModel> _stockOrders = [];
  StockOrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;
  bool _hasInitialized = false;

  // Getters
  List<StockOrderModel> get stockOrders => _stockOrders;
  StockOrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load stock orders list with optional status filter
  Future<void> loadStockOrders({
    bool forceReload = false,
    String? status,
    int? forTechnicianId,
  }) async {
    if (_isLoading && !forceReload) {
      print('⚠️ StockOrderProvider: Already loading, skipping duplicate call...');
      return;
    }
    
    if (!forceReload && _hasInitialized && _stockOrders.isNotEmpty) {
      print('⚠️ StockOrderProvider: Already initialized with data, skipping...');
      return;
    }
    
    print('🔄 StockOrderProvider.loadStockOrders() - Starting...');
    print('   Status filter: $status');
    print('   For Technician ID: $forTechnicianId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📞 StockOrderProvider: Calling StockOrderApi.getStockOrders()...');
      _stockOrders = await StockOrderApi.getStockOrders(
        status: status,
        forTechnicianId: forTechnicianId,
      );
      
      print('📦 StockOrderProvider: Received ${_stockOrders.length} stock orders');
      
      _hasInitialized = true;
      
      if (_stockOrders.isEmpty) {
        print('⚠️ StockOrderProvider: No stock orders returned');
        _error = 'No stock orders found.';
      } else {
        print('✅ StockOrderProvider: Successfully loaded ${_stockOrders.length} stock orders');
        _error = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ StockOrderProvider.loadStockOrders() ERROR:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      
      _hasInitialized = true;
      _isLoading = false;
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _error = 'Unauthorized. Please login again.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        _error = 'You do not have permission to view stock orders.';
      } else {
        _error = 'Failed to load stock orders: ${e.toString()}';
      }
      notifyListeners();
    }
  }

  /// Load single stock order by ID
  Future<void> loadStockOrderById(int id, {bool forceReload = false}) async {
    if (!forceReload && _isLoading) return;
    if (!forceReload && _selectedOrder != null && _selectedOrder!.id == id) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await StockOrderApi.getStockOrderById(id);
      _isLoading = false;
      if (_selectedOrder == null) {
        _error = 'Stock order not found';
      } else {
        _error = null;
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _error = 'Unauthorized. Please login again.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        _error = 'You do not have permission to view this stock order.';
      } else {
        _error = 'Failed to load stock order: ${e.toString()}';
      }
      notifyListeners();
    }
  }

  /// Create stock order
  Future<Map<String, dynamic>> createStockOrder(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.createStockOrder(data);
      _isLoading = false;
      
      if (result['success'] == true) {
        // Reload the list
        await loadStockOrders(forceReload: true);
        return result;
      } else {
        _error = result['message'] ?? 'Failed to create stock order';
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
  /// Approve stock order by Team Leader
  Future<Map<String, dynamic>> approveByTeamLeader(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.approveByTeamLeader(id);
      _isLoading = false;
      
      if (result['success'] == true) {
        // Reload the list
        await loadStockOrders(status: 'pending_team_leader', forceReload: true);
        // Reload the selected order if it's the same one
        if (_selectedOrder?.id == id) {
          await loadStockOrderById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to approve stock order';
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

  /// Reject stock order by Team Leader
  Future<Map<String, dynamic>> rejectByTeamLeader(int id, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.rejectByTeamLeader(id, reason: reason);
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadStockOrders(status: 'pending_team_leader', forceReload: true);
        if (_selectedOrder?.id == id) {
          await loadStockOrderById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to reject stock order';
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

  /// Approve stock order by Manager
  Future<Map<String, dynamic>> approveByManager(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.approveByManager(id);
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadStockOrders(status: 'approved_by_team_leader', forceReload: true);
        if (_selectedOrder?.id == id) {
          await loadStockOrderById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to approve stock order';
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

  /// Reject stock order by Manager
  Future<Map<String, dynamic>> rejectByManager(int id, {String? reason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.rejectByManager(id, reason: reason);
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadStockOrders(status: 'approved_by_team_leader', forceReload: true);
        if (_selectedOrder?.id == id) {
          await loadStockOrderById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to reject stock order';
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

  /// Issue stock order by Store Keeper
  Future<Map<String, dynamic>> issueStock(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.issueStock(id);
      _isLoading = false;
      
      if (result['success'] == true) {
        await loadStockOrders(status: 'pending_store_keeper', forceReload: true);
        if (_selectedOrder?.id == id) {
          await loadStockOrderById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to issue stock';
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

  /// Accept stock order by Technician
  Future<Map<String, dynamic>> acceptStock(int id, {int? technicianId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.acceptStock(id);
      _isLoading = false;
      
      if (result['success'] == true) {
        // Reload with technician filter
        if (technicianId != null) {
          await loadStockOrders(
            status: 'issued',
            forTechnicianId: technicianId,
            forceReload: true,
          );
        }
        if (_selectedOrder?.id == id) {
          await loadStockOrderById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to accept stock';
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

  /// Reject stock order by Technician
  Future<Map<String, dynamic>> rejectStock(int id, {String? reason, int? technicianId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StockOrderApi.rejectStock(id, reason: reason);
      _isLoading = false;
      
      if (result['success'] == true) {
        if (technicianId != null) {
          await loadStockOrders(
            status: 'issued',
            forTechnicianId: technicianId,
            forceReload: true,
          );
        }
        if (_selectedOrder?.id == id) {
          await loadStockOrderById(id, forceReload: true);
        }
        return result;
      } else {
        _error = result['message'] ?? 'Failed to reject stock order';
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

  void clearCache() {
    _hasInitialized = false;
    _stockOrders = [];
    _selectedOrder = null;
    _error = null;
    notifyListeners();
  }
}

