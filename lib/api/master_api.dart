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
  static Future<Map<int, ItemModel>> getItems({String? status}) async {
    try {
      String endpoint = '/items';
      if (status != null) {
        endpoint += '?status=$status';
      }
      final response = await ApiClient.get(endpoint);
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, ItemModel>{};
          for (var item in data) {
            final model = ItemModel.fromJson(item as Map<String, dynamic>);
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

  /// Get technicians (users with role=technician)
  static Future<Map<int, DropdownModel>> getTechnicians() async {
    try {
      // Try dropdown endpoint first, fallback to direct endpoint
      try {
        final response = await ApiClient.get('/dropdowns/technicians');
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
      } catch (e) {
        print('Dropdown endpoint failed, trying direct endpoint: $e');
      }
      
      // Fallback to direct endpoint
      final response = await ApiClient.get('/users?role=technician');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'];
        if (data is List) {
          final map = <int, DropdownModel>{};
          for (var item in data) {
            final itemMap = item as Map<String, dynamic>;
            // Create DropdownModel from user data
            final model = DropdownModel(
              id: itemMap['id'] is int ? itemMap['id'] : int.parse(itemMap['id'].toString()),
              name: itemMap['name']?.toString() ?? '',
              value: itemMap['name']?.toString() ?? '',
            );
            map[model.id] = model;
          }
          return map;
        }
      }
      return {};
    } catch (e) {
      print('Error fetching technicians: $e');
      return {};
    }
  }

  /// Get godowns
  static Future<Map<int, DropdownModel>> getGodowns() async {
    try {
      // Try dropdown endpoint first, fallback to direct endpoint
      try {
        final response = await ApiClient.get('/dropdowns/godowns');
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
      } catch (e) {
        print('Dropdown endpoint failed, trying direct endpoint: $e');
      }
      
      // Fallback to direct endpoint
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

  /// Load all dropdowns from /api/meta endpoint
  static Future<Map<String, dynamic>> loadMetaData() async {
    try {
      print('=== MasterApi.loadMetaData: Fetching from /api/meta ===');
      final response = await ApiClient.get('/meta');
      final result = ApiClient.handleResponse(response);
      
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          final metaData = <String, Map<int, DropdownModel>>{};
          
          // Parse vendor_types
          if (data['vendor_types'] != null && data['vendor_types'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['vendor_types'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['vendorTypes'] = map;
          }
          
          // Parse purchase_modes
          if (data['purchase_modes'] != null && data['purchase_modes'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['purchase_modes'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['purchaseModes'] = map;
          }
          
          // Parse payment_options
          if (data['payment_options'] != null && data['payment_options'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['payment_options'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['paymentOptions'] = map;
          }
          
          // Parse priorities
          if (data['priorities'] != null && data['priorities'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['priorities'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['priorities'] = map;
          }
          
          // Parse statuses
          if (data['statuses'] != null && data['statuses'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['statuses'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['statuses'] = map;
          }
          
          // Parse item_categories
          if (data['item_categories'] != null && data['item_categories'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['item_categories'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['itemCategories'] = map;
          }
          
          // Parse units
          if (data['units'] != null && data['units'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['units'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['units'] = map;
          }
          
          // Parse godowns
          if (data['godowns'] != null && data['godowns'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['godowns'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['godowns'] = map;
          }
          
          // Parse technicians
          if (data['technicians'] != null && data['technicians'] is List) {
            final map = <int, DropdownModel>{};
            for (var item in data['technicians'] as List) {
              final model = DropdownModel.fromJson(item as Map<String, dynamic>);
              map[model.id] = model;
            }
            metaData['technicians'] = map;
          }
          
          print('✅ Meta data loaded: ${metaData.keys.join(", ")}');
          return metaData;
        }
      }
      return {};
    } catch (e) {
      print('❌ Error loading meta data: $e');
      return {};
    }
  }

  /// Load all master data in parallel
  static Future<Map<String, dynamic>> loadAllMasterData() async {
    print('=== MasterApi.loadAllMasterData: Starting parallel load ===');
    try {
      // First, try to load from /api/meta
      final metaData = await loadMetaData();
      
      // Load other data that's not in meta endpoint
      final results = await Future.wait([
        getRoles(),
        getItemTypes(),
        getGstClasses(),
        getItemStatuses(),
        getSuppliers(),
        getItems(),
        getItems(status: 'active'), // Active items
        getPlants(),
        getServiceTasks(),
      ]);

      print('=== All API calls completed ===');
      
      // Merge meta data with other data
      final data = <String, dynamic>{
        'roles': results[0],
        'itemTypes': results[1],
        'gstClasses': results[2],
        'itemStatuses': results[3],
        'suppliers': results[4],
        'items': results[5],
        'activeItems': results[6],
        'plants': results[7],
        'serviceTasks': results[8],
      };
      
      // Use meta data if available, otherwise fallback to individual calls
      if (metaData.isNotEmpty) {
        data['vendorTypes'] = metaData['vendorTypes'] ?? await getVendorTypes();
        data['purchaseModes'] = metaData['purchaseModes'] ?? await getPurchaseModes();
        data['priorities'] = metaData['priorities'] ?? await getPriorities();
        data['paymentOptions'] = metaData['paymentOptions'] ?? await getPaymentOptions();
        data['godowns'] = metaData['godowns'] ?? await getGodowns();
        data['technicians'] = metaData['technicians'] ?? await getTechnicians();
      } else {
        // Fallback to individual API calls if meta endpoint fails
        print('⚠️ Meta endpoint failed, using individual API calls');
        final fallbackResults = await Future.wait([
          getVendorTypes(),
          getPurchaseModes(),
          getPriorities(),
          getPaymentOptions(),
          getGodowns(),
          getTechnicians(),
        ]);
        data['vendorTypes'] = fallbackResults[0];
        data['purchaseModes'] = fallbackResults[1];
        data['priorities'] = fallbackResults[2];
        data['paymentOptions'] = fallbackResults[3];
        data['godowns'] = fallbackResults[4];
        data['technicians'] = fallbackResults[5];
      }
      
      print('=== Returning master data map ===');
      return data;
    } catch (e) {
      print('❌ Error loading master data: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
}

