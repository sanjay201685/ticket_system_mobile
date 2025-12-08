import 'package:flutter/foundation.dart';
import '../api/purchase_api.dart';
import '../models/purchase_item_model.dart';

class PurchaseRequestProvider with ChangeNotifier {
  bool _isSubmitting = false;
  String? _error;

  // Form fields
  int? _vendorTypeId;  // ID for vendor_type
  String? _vendorType;  // Key/value string (e.g., 'registered', 'other') - kept for backward compatibility
  int? _vendorId;
  String? _vendorName;  // Required if vendor_type is 'other'
  int? _purchaseModeId;  // ID for purchase_mode
  String? _purchaseMode;  // Key/value for purchase_mode (alternative to ID)
  int? _paymentOptionId;  // ID for payment_option
  String? _paymentOption;  // Key/value for payment_option (alternative to ID)
  int? _priorityId;  // ID for priority
  String? _priority;  // Key/value for priority (alternative to ID)
  int? _siteId;
  DateTime? _requiredByDate;
  String _description = '';  // Changed from notes to description
  List<PurchaseItemModel> _items = [];

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  // Getters
  int? get vendorTypeId => _vendorTypeId;
  String? get vendorType => _vendorType;
  int? get vendorId => _vendorId;
  String? get vendorName => _vendorName;
  int? get purchaseModeId => _purchaseModeId;
  String? get purchaseMode => _purchaseMode;
  int? get paymentOptionId => _paymentOptionId;
  String? get paymentOption => _paymentOption;
  int? get priorityId => _priorityId;
  String? get priority => _priority;
  int? get siteId => _siteId;
  DateTime? get requiredByDate => _requiredByDate;
  String get description => _description;
  List<PurchaseItemModel> get items => _items;

  // Setters
  void setVendorTypeId(int? id) {
    _vendorTypeId = id;
    notifyListeners();
  }

  void setVendorType(String? value) {
    _vendorType = value;
    notifyListeners();
  }

  void setVendorId(int? value) {
    _vendorId = value;
    notifyListeners();
  }

  void setVendorName(String? value) {
    _vendorName = value;
    notifyListeners();
  }

  void setPurchaseModeId(int? id) {
    _purchaseModeId = id;
    _purchaseMode = null;  // Clear key when ID is set
    notifyListeners();
  }

  void setPurchaseMode(String? key) {
    _purchaseMode = key;
    _purchaseModeId = null;  // Clear ID when key is set
    notifyListeners();
  }

  void setPaymentOptionId(int? id) {
    _paymentOptionId = id;
    _paymentOption = null;  // Clear key when ID is set
    notifyListeners();
  }

  void setPaymentOption(String? key) {
    _paymentOption = key;
    _paymentOptionId = null;  // Clear ID when key is set
    notifyListeners();
  }

  void setPriorityId(int? id) {
    _priorityId = id;
    _priority = null;  // Clear key when ID is set
    notifyListeners();
  }

  void setPriority(String? key) {
    _priority = key;
    _priorityId = null;  // Clear ID when key is set
    notifyListeners();
  }

  void setSiteId(int? value) {
    _siteId = value;
    notifyListeners();
  }

  void setRequiredByDate(DateTime? value) {
    _requiredByDate = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void addItem() {
    _items.add(PurchaseItemModel());
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void updateItem(int index, PurchaseItemModel item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      notifyListeners();
    }
  }

  /// Validate form
  String? validateForm() {
    print('=== Provider validateForm called ===');
    
    if (_vendorTypeId == null) {
      print('❌ Validation failed: Vendor type ID is null');
      return 'Please select vendor type';
    }
    print('✅ Vendor type ID: $_vendorTypeId');
    
    // If vendor_type_id is 1 (registered), vendor_id is required
    if (_vendorTypeId == 1 && _vendorId == null) {
      print('❌ Validation failed: Vendor ID is required for registered vendor');
      return 'Please select vendor';
    }
    
    // If vendor_type_id is 2 (other), BOTH vendor_id AND vendor_name are required
    if (_vendorTypeId == 2) {
      if (_vendorId == null) {
        print('❌ Validation failed: Vendor ID is required for other vendor');
        return 'Please select vendor';
      }
      if (_vendorName == null || _vendorName!.isEmpty) {
        print('❌ Validation failed: Vendor name is required for other vendor');
        return 'Please enter vendor name';
      }
    }
    
    if (_vendorId != null) {
      print('✅ Vendor ID: $_vendorId');
    }
    if (_vendorName != null && _vendorName!.isNotEmpty) {
      print('✅ Vendor name: $_vendorName');
    }
    
    // Purchase mode: ID must be set (we only send IDs now)
    if (_purchaseModeId == null) {
      print('❌ Validation failed: Purchase mode is not set');
      return 'Please select purchase mode';
    }
    print('✅ Purchase mode: ID=$_purchaseModeId');
    
    // Priority: ID must be set (we only send IDs now)
    if (_priorityId == null) {
      print('❌ Validation failed: Priority is not set');
      return 'Please select priority';
    }
    print('✅ Priority: ID=$_priorityId');
    
    if (_items.isEmpty) {
      print('❌ Validation failed: No items added');
      return 'Please add at least one item';
    }
    print('✅ Items count: ${_items.length}');

    // Validate items
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.itemId == null) {
        print('❌ Validation failed: Item ${i + 1} - itemId is null');
        return 'Please select item for row ${i + 1}';
      }
      if (item.qtyRequired <= 0) {
        print('❌ Validation failed: Item ${i + 1} - qtyRequired is ${item.qtyRequired}');
        return 'Quantity must be greater than 0 for row ${i + 1}';
      }
      if (item.unitPrice <= 0) {
        print('❌ Validation failed: Item ${i + 1} - unitPrice is ${item.unitPrice}');
        return 'Unit price must be greater than 0 for row ${i + 1}';
      }
      print('✅ Item ${i + 1}: itemId=${item.itemId}, qty=${item.qtyRequired}, price=${item.unitPrice}');
    }

    print('✅ All validations passed!');
    return null;
  }

  /// Submit purchase request
  Future<Map<String, dynamic>> submit({int? clientId}) async {
    final validationError = validateForm();
    if (validationError != null) {
      return {
        'success': false,
        'message': validationError,
      };
    }

    if (clientId == null) {
      return {
        'success': false,
        'message': 'Client ID is required',
      };
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final data = <String, dynamic>{
        //'client_id': clientId,  // Always include
        'client_id': null,  // Always include
        'site_id': _siteId,  // Always include, even if null
        'vendor_id': _vendorId,  // Always include, even if null
        'vendor_type_id': _vendorTypeId,  // Send vendor_type_id instead of vendor_type string
        if (_vendorName != null && _vendorName!.isNotEmpty) 'vendor_name': _vendorName,  // Include if provided
        'purchase_mode_id': _purchaseModeId,  // Always include, even if null (only ID, no key)
        'payment_option_id': _paymentOptionId,  // Always include, even if null (only ID, no key)
        'priority_id': _priorityId,  // Always include, even if null (only ID, no key)
        'items': _items.map((item) => {
          'item_id': item.itemId,
          'qty_required': item.qtyRequired,
          'est_unit_price': item.unitPrice ?? 0.0,  // Always include, use 0.0 if null
          'gst_percent': item.gstPercent ?? 0.0,  // Always include, use 0.0 if null
        }).toList(),
      };

      print('=== Sending data to API ===');
      print('Data: $data');
      print('Data JSON: ${data.toString()}');

      final result = await PurchaseApi.createPurchaseRequest(data);
      
      print('=== API Response ===');
      print('Result: $result');
      
      _isSubmitting = false;
      if (result['success'] == true) {
        _error = null;
        notifyListeners();
        return result;
      } else {
        _error = result['message'] ?? 'Failed to create purchase request';
        notifyListeners();
        return result;
      }
    } catch (e) {
      _isSubmitting = false;
      _error = 'Error: ${e.toString()}';
      notifyListeners();
      return {
        'success': false,
        'message': _error,
      };
    }
  }

  /// Reset form
  void reset() {
    _vendorTypeId = null;
    _vendorType = null;
    _vendorId = null;
    _vendorName = null;
    _purchaseModeId = null;
    _purchaseMode = null;
    _paymentOptionId = null;
    _paymentOption = null;
    _priorityId = null;
    _priority = null;
    _siteId = null;
    _requiredByDate = null;
    _description = '';
    _items = [];
    _error = null;
    notifyListeners();
  }
}



