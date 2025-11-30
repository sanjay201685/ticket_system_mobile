import 'api_client.dart';
import '../models/dropdown_model.dart';
import '../models/supplier_model.dart';
import '../models/item_model.dart';

class MasterApi {
  /// Get all roles
  static Future<Map<int, DropdownModel>> getRoles() async {
    try {
      final response = await ApiClient.get('/meta/roles');
      final result = ApiClient.handleResponse(response);
      print('Roles API Response body: ${response.body}');

      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching roles: $e');
      return {};
    }
  }

  /// Get vendor types
  static Future<Map<int, DropdownModel>> getVendorTypes() async {
    try {
      print('=== API: Fetching vendor types ===');
      print('API Endpoint: /meta/vendor-types');
      final response = await ApiClient.get('/meta/vendor-types');
      print('API Response received: ${response.statusCode}');
      print('Vender type API Response body: ${response.body}');
      
      final result = ApiClient.handleResponse(response);
      print('Handled response result: $result');
      
      if (result['success'] == true) {
        var data = result['data'];
        print('API Success: true, data type: ${data.runtimeType}');
        print('Data content: $data');
        
        // Data should already be extracted by handleResponse, but handle edge cases
        if (data is Map && data.containsKey('data')) {
          print('Found nested data structure, extracting inner data');
          data = data['data'];
          print('Extracted data type: ${data.runtimeType}');
        }
        
        if (data is List) {
          print('✅ Data is List, length: ${data.length}');
          if (data.isEmpty) {
            print('⚠️ WARNING: List is empty!');
          }
          final map = <int, DropdownModel>{};
          for (var item in data) {
            print('  Parsing vendor type item: $item');
            try {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
              print('  - Vendor Type: id=${model.id}, name=${model.name}, value=${model.value}');
            } catch (e) {
              print('  ❌ Error parsing item: $e');
              rethrow;
            }
          }
          print('✅ Vendor types parsed: ${map.length} items');
          return map;
        } else {
          print('⚠️ WARNING: data is not a List, it is: ${data.runtimeType}');
          print('Full data content: $data');
        }
      } else {
        print('⚠️ WARNING: API success is false or null');
        print('Full result: $result');
      }
      print('❌ Returning empty map for vendor types');
      return {};
    } catch (e) {
      print('❌ Error fetching vendor types: $e');
      print('Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  /// Get purchase modes
  static Future<Map<int, DropdownModel>> getPurchaseModes() async {
    try {
      final response = await ApiClient.get('/meta/purchase-modes');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching purchase modes: $e');
      return {};
    }
  }

  /// Get priorities
  static Future<Map<int, DropdownModel>> getPriorities() async {
    try {
      final response = await ApiClient.get('/meta/priorities');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching priorities: $e');
      return {};
    }
  }

  /// Get payment options
  static Future<Map<int, DropdownModel>> getPaymentOptions() async {
    try {
      final response = await ApiClient.get('/meta/payment-options');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching payment options: $e');
      return {};
    }
  }

  /// Get item types
  static Future<Map<int, DropdownModel>> getItemTypes() async {
    try {
      final response = await ApiClient.get('/items/types');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching item types: $e');
      return {};
    }
  }

  /// Get GST classes
  static Future<Map<int, DropdownModel>> getGstClasses() async {
    try {
      final response = await ApiClient.get('/items/gst-classes');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching GST classes: $e');
      return {};
    }
  }

  /// Get item statuses
  static Future<Map<int, DropdownModel>> getItemStatuses() async {
    try {
      final response = await ApiClient.get('/items/statuses');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching item statuses: $e');
      return {};
    }
  }

  /// Get suppliers
  static Future<Map<int, SupplierModel>> getSuppliers() async {
    try {
      print('=== API: Fetching suppliers ===');
      print('API Endpoint: /suppliers');
      final response = await ApiClient.get('/suppliers');
      print('API Response received: ${response.statusCode}');
      print('API Response body: ${response.body}');
      
      final result = ApiClient.handleResponse(response);
      print('Handled response result: $result');
      
      if (result['success'] == true) {
        var data = result['data'];
        print('API Success: true, data type: ${data.runtimeType}');
        print('Data content: $data');
        
        // Data should already be extracted by handleResponse, but handle edge cases
        if (data is Map && data.containsKey('data')) {
          print('Found nested data structure, extracting inner data');
          data = data['data'];
          print('Extracted data type: ${data.runtimeType}');
        }
        
        if (data is List) {
          print('✅ Data is List, length: ${data.length}');
          if (data.isEmpty) {
            print('⚠️ WARNING: List is empty!');
          }
          final map = <int, SupplierModel>{};
          for (var item in data) {
            print('  Parsing supplier item: $item');
            try {
              final model = SupplierModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
              print('  - Supplier: id=${model.id}, name=${model.name}');
            } catch (e) {
              print('  ❌ Error parsing item: $e');
              rethrow;
            }
          }
          print('✅ Suppliers parsed: ${map.length} items');
          return map;
        } else {
          print('⚠️ WARNING: data is not a List, it is: ${data.runtimeType}');
          print('Full data content: $data');
        }
      } else {
        print('⚠️ WARNING: API success is false or null');
        print('Full result: $result');
      }
      print('❌ Returning empty map for suppliers');
      return {};
    } catch (e) {
      print('❌ Error fetching suppliers: $e');
      print('Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  /// Get items
  static Future<Map<int, ItemModel>> getItems() async {
    try {
      final response = await ApiClient.get('/items');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, ItemModel>{};
          for (var item in data) {
            final model = ItemModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching items: $e');
      return {};
    }
  }

  /// Get godowns
  static Future<Map<int, DropdownModel>> getGodowns() async {
    try {
      final response = await ApiClient.get('/godowns');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching godowns: $e');
      return {};
    }
  }

  /// Get plants (sites)
  static Future<Map<int, DropdownModel>> getPlants() async {
    try {
      final response = await ApiClient.get('/plants');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching plants: $e');
      return {};
    }
  }

  /// Get service tasks
  static Future<Map<int, DropdownModel>> getServiceTasks() async {
    try {
      final response = await ApiClient.get('/service-tasks');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final model = DropdownModel.fromJson(item as Map<String, dynamic>);
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching service tasks: $e');
      return {};
    }
  }

  /// Load all master data in parallel
  static Future<Map<String, dynamic>> loadAllMasterData() async {
    print('=== MasterApi.loadAllMasterData: Starting parallel load ===');
    try {
      final results = await Future.wait([
        getRoles(),
        getVendorTypes(),
        getPurchaseModes(),
        getPriorities(),
        getPaymentOptions(),
        getItemTypes(),
        getGstClasses(),
        getItemStatuses(),
        getSuppliers(),
        getItems(),
        getGodowns(),
        getPlants(),
        getServiceTasks(),
      ]);

      print('=== All API calls completed ===');
      print('Results count: ${results.length}');
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final names = ['roles', 'vendorTypes', 'purchaseModes', 'priorities', 'paymentOptions', 
                      'itemTypes', 'gstClasses', 'itemStatuses', 'suppliers', 'items', 'godowns', 'plants', 'serviceTasks'];
        print('  ${names[i]}: ${result.length} items');
      }

      final data = {
        'roles': results[0],
        'vendorTypes': results[1],
        'purchaseModes': results[2],
        'priorities': results[3],
        'paymentOptions': results[4],
        'itemTypes': results[5],
        'gstClasses': results[6],
        'itemStatuses': results[7],
        'suppliers': results[8],
        'items': results[9],
        'godowns': results[10],
        'plants': results[11],
        'serviceTasks': results[12],
      };
      
      print('=== Returning master data map ===');
      print('Returning master data map: ${data}');
      return data;
    } catch (e) {
      print('❌ Error loading master data: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}

