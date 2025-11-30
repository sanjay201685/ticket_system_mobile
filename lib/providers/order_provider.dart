import 'package:flutter/material.dart';
import '../api/order_api.dart';
import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;
  
  // Filters
  String? _statusFilter;
  String? _vendorTypeFilter;
  DateTime? _fromDateFilter;
  DateTime? _toDateFilter;

  // Getters
  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String? get vendorTypeFilter => _vendorTypeFilter;
  DateTime? get fromDateFilter => _fromDateFilter;
  DateTime? get toDateFilter => _toDateFilter;

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await OrderApi.getOrders(
        status: _statusFilter,
        vendorType: _vendorTypeFilter,
        fromDate: _fromDateFilter,
        toDate: _toDateFilter,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load orders: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadOrderById(int orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedOrder = await OrderApi.getOrderById(orderId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load order: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await OrderApi.updateOrderStatus(orderId, status);
      _isLoading = false;
      
      if (result['success'] == true) {
        // Reload orders
        await loadOrders();
        return true;
      } else {
        _error = result['message'] ?? 'Failed to update order status';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setVendorTypeFilter(String? vendorType) {
    _vendorTypeFilter = vendorType;
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    _fromDateFilter = from;
    _toDateFilter = to;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _vendorTypeFilter = null;
    _fromDateFilter = null;
    _toDateFilter = null;
    notifyListeners();
  }
}

