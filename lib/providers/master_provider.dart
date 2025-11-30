import 'package:flutter/foundation.dart';
import '../api/master_api.dart';
import '../models/dropdown_model.dart';
import '../models/supplier_model.dart';
import '../models/item_model.dart';

class MasterProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // Master data stored as maps (ID as key, model as value)
  Map<int, DropdownModel> _roles = {};
  Map<int, DropdownModel> _vendorTypes = {};
  Map<int, DropdownModel> _purchaseModes = {};
  Map<int, DropdownModel> _priorities = {};
  Map<int, DropdownModel> _paymentOptions = {};
  Map<int, DropdownModel> _itemTypes = {};
  Map<int, DropdownModel> _gstClasses = {};
  Map<int, DropdownModel> _itemStatuses = {};
  Map<int, SupplierModel> _suppliers = {};
  Map<int, ItemModel> _items = {};
  Map<int, DropdownModel> _godowns = {};
  Map<int, DropdownModel> _plants = {};
  Map<int, DropdownModel> _serviceTasks = {};

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters - return lists for backward compatibility
  List<DropdownModel> get roles => _roles.values.toList();
  List<DropdownModel> get vendorTypes => _vendorTypes.values.toList();
  List<DropdownModel> get purchaseModes => _purchaseModes.values.toList();
  List<DropdownModel> get priorities => _priorities.values.toList();
  List<DropdownModel> get paymentOptions => _paymentOptions.values.toList();
  List<DropdownModel> get itemTypes => _itemTypes.values.toList();
  List<DropdownModel> get gstClasses => _gstClasses.values.toList();
  List<DropdownModel> get itemStatuses => _itemStatuses.values.toList();
  List<SupplierModel> get suppliers => _suppliers.values.toList();
  List<ItemModel> get items => _items.values.toList();
  List<DropdownModel> get godowns => _godowns.values.toList();
  List<DropdownModel> get plants => _plants.values.toList();
  List<DropdownModel> get serviceTasks => _serviceTasks.values.toList();

  /// Load all master data
  Future<void> loadAllMasterData() async {
    print('=== MasterProvider.loadAllMasterData called ===');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await MasterApi.loadAllMasterData();
      
      print('=== Master data received from API ===');
      print('roles count: ${(data['roles'] as Map).length}');
      print('vendorTypes count: ${(data['vendorTypes'] as Map).length}');
      print('purchaseModes count: ${(data['purchaseModes'] as Map).length}');
      print('priorities count: ${(data['priorities'] as Map).length}');
      print('paymentOptions count: ${(data['paymentOptions'] as Map).length}');
      print('suppliers count: ${(data['suppliers'] as Map).length}');
      print('items count: ${(data['items'] as Map).length}');
      print('godowns count: ${(data['godowns'] as Map).length}');
      print('plants count: ${(data['plants'] as Map).length}');
      
      // Print vendor types details
      if ((data['vendorTypes'] as Map).isNotEmpty) {
        print('=== Vendor Types Details ===');
        for (var vt in (data['vendorTypes'] as Map).values) {
          print('Vendor Type: ${vt.toString()}');
        }
      } else {
        print('⚠️ WARNING: vendorTypes map is EMPTY!');
      }
      
      _roles = data['roles'] as Map<int, DropdownModel>;
      _vendorTypes = data['vendorTypes'] as Map<int, DropdownModel>;
      _purchaseModes = data['purchaseModes'] as Map<int, DropdownModel>;
      _priorities = data['priorities'] as Map<int, DropdownModel>;
      _paymentOptions = data['paymentOptions'] as Map<int, DropdownModel>;
      _itemTypes = data['itemTypes'] as Map<int, DropdownModel>;
      _gstClasses = data['gstClasses'] as Map<int, DropdownModel>;
      _itemStatuses = data['itemStatuses'] as Map<int, DropdownModel>;
      _suppliers = data['suppliers'] as Map<int, SupplierModel>;
      _items = data['items'] as Map<int, ItemModel>;
      _godowns = data['godowns'] as Map<int, DropdownModel>;
      _plants = data['plants'] as Map<int, DropdownModel>;
      _serviceTasks = data['serviceTasks'] as Map<int, DropdownModel>;

      print('=== Data assigned to provider ===');
      print('_vendorTypes.length: ${_vendorTypes.length}');
      print('_suppliers.length: ${_suppliers.length}');
      
      _isLoading = false;
      _error = null;
      notifyListeners();
      print('=== MasterProvider data loaded successfully ===');
    } catch (e) {
      print('❌ ERROR in loadAllMasterData: $e');
      _isLoading = false;
      _error = 'Failed to load master data: ${e.toString()}';
      notifyListeners();
    }
  }
}


