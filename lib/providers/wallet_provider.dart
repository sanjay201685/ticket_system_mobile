import 'package:flutter/foundation.dart';
import '../api/wallet_api.dart';
import '../models/wallet_transaction_model.dart';

class WalletProvider with ChangeNotifier {
  List<WalletTransaction> _transactions = [];
  WalletBalance? _balance;
  bool _isLoading = false;
  bool _isLoadingBalance = false;
  String? _error;
  bool _hasInitialized = false;

  // Filters
  int? _userIdFilter;
  String? _typeFilter; // 'credit' or 'debit'
  String? _statusFilter; // 'pending', 'paid', 'failed'
  int _limit = 50;

  // Getters
  List<WalletTransaction> get transactions => _transactions;
  WalletBalance? get balance => _balance;
  bool get isLoading => _isLoading;
  bool get isLoadingBalance => _isLoadingBalance;
  String? get error => _error;
  int? get userIdFilter => _userIdFilter;
  String? get typeFilter => _typeFilter;
  String? get statusFilter => _statusFilter;
  int get limit => _limit;

  /// Load transaction history
  Future<void> loadTransactions({
    bool forceReload = false,
    int? userId,
    String? type,
    String? status,
    int? limit,
  }) async {
    // Prevent multiple simultaneous loads
    if (_isLoading && !forceReload) {
      print('⚠️ WalletProvider: Already loading, skipping duplicate call...');
      return;
    }

    // Update filters
    if (userId != null) {
      _userIdFilter = userId;
    }
    if (type != null) {
      _typeFilter = type.isEmpty ? null : type;
    }
    if (status != null) {
      _statusFilter = status.isEmpty ? null : status;
    }
    if (limit != null) {
      _limit = limit;
    }

    // If already initialized with data and not forcing reload, skip
    if (!forceReload && _hasInitialized && _transactions.isNotEmpty) {
      print('⚠️ WalletProvider: Already initialized with data, skipping...');
      return;
    }

    print('🔄 WalletProvider.loadTransactions() - Starting...');
    print('   User ID: $_userIdFilter');
    print('   Type: $_typeFilter');
    print('   Status: $_statusFilter');
    print('   Limit: $_limit');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await WalletApi.getTransactions(
        userId: _userIdFilter,
        type: _typeFilter,
        status: _statusFilter,
        limit: _limit,
      );

      print('📦 WalletProvider: Received ${_transactions.length} transactions');

      _hasInitialized = true;

      if (_transactions.isEmpty) {
        print('⚠️ WalletProvider: No transactions returned');
        _error = 'No transactions found.';
      } else {
        print('✅ WalletProvider: Successfully loaded ${_transactions.length} transactions');
        _error = null;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ WalletProvider.loadTransactions() ERROR:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');

      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _hasInitialized = true; // Mark as initialized even on error
      notifyListeners();
    }
  }

  /// Load wallet balance
  Future<void> loadBalance(int userId, {bool forceReload = false}) async {
    // Prevent multiple simultaneous loads
    if (_isLoadingBalance && !forceReload) {
      print('⚠️ WalletProvider: Already loading balance, skipping...');
      return;
    }

    // If balance already loaded for this user and not forcing reload, skip
    if (!forceReload && _balance != null && _balance!.userId == userId) {
      print('⚠️ WalletProvider: Balance already loaded for user $userId, skipping...');
      return;
    }

    print('🔄 WalletProvider.loadBalance() - Starting for user $userId...');

    _isLoadingBalance = true;
    _error = null;
    notifyListeners();

    try {
      _balance = await WalletApi.getWalletBalance(userId);
      print('✅ WalletProvider: Successfully loaded balance: ${_balance!.formattedBalance}');

      _isLoadingBalance = false;
      notifyListeners();
    } catch (e, stackTrace) {
      print('❌ WalletProvider.loadBalance() ERROR:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');

      _error = e.toString().replaceAll('Exception: ', '');
      _isLoadingBalance = false;
      notifyListeners();
    }
  }

  /// Create a new transaction
  Future<Map<String, dynamic>> createTransaction({
    required int userId,
    required String transactionType,
    required double amount,
    String? referenceType,
    int? referenceId,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await WalletApi.createTransaction(
        userId: userId,
        transactionType: transactionType,
        amount: amount,
        referenceType: referenceType,
        referenceId: referenceId,
        notes: notes,
      );

      if (result['success'] == true) {
        // Reload transactions and balance after successful creation
        await Future.wait([
          loadTransactions(forceReload: true),
          loadBalance(userId, forceReload: true),
        ]);

        _isLoading = false;
        notifyListeners();
        return result;
      } else {
        _error = result['message'] ?? 'Failed to create transaction';
        _isLoading = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': _error ?? 'Failed to create transaction',
      };
    }
  }

  /// Clear filters
  void clearFilters() {
    _userIdFilter = null;
    _typeFilter = null;
    _statusFilter = null;
    _limit = 50;
    notifyListeners();
  }

  /// Reset provider state
  void reset() {
    _transactions = [];
    _balance = null;
    _isLoading = false;
    _isLoadingBalance = false;
    _error = null;
    _hasInitialized = false;
    clearFilters();
    notifyListeners();
  }
}
