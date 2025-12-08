class StockOrderModel {
  final int id;
  final String? orderNo;
  final String? createdByName;
  final String? createdByRole;
  final String? status;
  final int totalItems;
  final DateTime? createdAt;
  final List<StockOrderItemModel> items;
  final String? targetGodownName;
  final String? remarks;
  final bool canIssue;
  final bool canAccept;

  StockOrderModel({
    required this.id,
    this.orderNo,
    this.createdByName,
    this.createdByRole,
    this.status,
    required this.totalItems,
    this.createdAt,
    this.items = const [],
    this.targetGodownName,
    this.remarks,
    this.canIssue = false,
    this.canAccept = false,
  });

  /// Safely get nested string value from a map, checking if parent is a Map first
  static String? _safeGetNestedString(Map<String, dynamic> json, String parentKey, String childKey) {
    final parent = json[parentKey];
    if (parent is Map<String, dynamic> || (parent is Map)) {
      try {
        return parent[childKey]?.toString();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory StockOrderModel.fromJson(Map<String, dynamic> json) {
    // Safely parse id
    int parsedId;
    try {
      if (json['id'] is int) {
        parsedId = json['id'] as int;
      } else if (json['id'] is String) {
        parsedId = int.parse(json['id'] as String);
      } else {
        parsedId = int.tryParse(json['id'].toString()) ?? 0;
      }
    } catch (e) {
      print('⚠️ StockOrderModel: Error parsing id: ${json['id']}, error: $e');
      parsedId = 0;
    }
    
    return StockOrderModel(
      id: parsedId,
      orderNo: json['order_no']?.toString() ?? 
               json['orderNo']?.toString() ??
               json['order_number']?.toString(),
    createdByName: json['created_by_name']?.toString() ??
                   _safeGetNestedString(json, 'technician', 'name') ??
                   _safeGetNestedString(json, 'for_technician', 'name') ??
                   _safeGetNestedString(json, 'created_by', 'name') ??
                   _safeGetNestedString(json, 'creator', 'name') ??
                   _safeGetNestedString(json, 'user', 'name') ??
                   json['technician_name']?.toString(),
    createdByRole: json['created_by_role']?.toString() ??
                   _safeGetNestedString(json, 'created_by', 'role') ??
                   _safeGetNestedString(json, 'creator', 'role'),
    status: (json['status'] is Map 
                ? _safeGetNestedString(json, 'status', 'key') 
                : json['status']?.toString()) ??
            _safeGetNestedString(json, 'status', 'key') ??
            _safeGetNestedString(json, 'status', 'name'),
      totalItems: json['total_items'] is int 
          ? json['total_items'] as int
          : json['total_items'] != null
              ? (int.tryParse(json['total_items'].toString()) ?? 0)
              : json['items_count'] is int
                  ? json['items_count'] as int
                  : json['items_count'] != null
                      ? (int.tryParse(json['items_count'].toString()) ?? 0)
                      : (json['items'] is List ? (json['items'] as List).length : 0),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      items: _parseItems(json['items']),
      targetGodownName: _safeGetNestedString(json, 'target_godown', 'name') ??
                       _safeGetNestedString(json, 'godown', 'name') ??
                       json['target_godown_name']?.toString(),
      remarks: json['remarks']?.toString(),
      canIssue: json['can_issue'] == true || json['can_issue'] == 1 || json['can_issue'] == '1',
      canAccept: json['can_accept'] == true || json['can_accept'] == 1 || json['can_accept'] == '1',
    );
  }

  /// Safely parse items array
  static List<StockOrderItemModel> _parseItems(dynamic itemsData) {
    List<StockOrderItemModel> parsedItems = [];
    if (itemsData != null && itemsData is List) {
      try {
        for (var item in itemsData) {
          try {
            if (item is Map) {
              // Recursively convert nested maps to Map<String, dynamic>
              final itemMap = _convertItemMap(item);
              parsedItems.add(StockOrderItemModel.fromJson(itemMap));
            }
          } catch (e) {
            print('⚠️ StockOrderModel: Error parsing item: $e');
            print('   Item data: $item');
            // Continue with next item
          }
        }
      } catch (e) {
        print('⚠️ StockOrderModel: Error parsing items array: $e');
      }
    }
    return parsedItems;
  }

  /// Recursively convert item map to Map<String, dynamic>
  static Map<String, dynamic> _convertItemMap(dynamic value) {
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, val) {
        final stringKey = key.toString();
        if (val is Map) {
          result[stringKey] = _convertItemMap(val);
        } else if (val is List) {
          result[stringKey] = val.map((item) {
            if (item is Map) {
              return _convertItemMap(item);
            }
            return item;
          }).toList();
        } else {
          result[stringKey] = val;
        }
      });
      return result;
    }
    return {};
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_no': orderNo,
      'created_by_name': createdByName,
      'created_by_role': createdByRole,
      'status': status,
      'total_items': totalItems,
      'created_at': createdAt?.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'target_godown_name': targetGodownName,
      'remarks': remarks,
    };
  }
}

class StockOrderItemModel {
  final int id;
  final int? itemId;
  final String? itemName;
  final double quantity;
  final double? availableStock;

  StockOrderItemModel({
    required this.id,
    this.itemId,
    this.itemName,
    required this.quantity,
    this.availableStock,
  });

  factory StockOrderItemModel.fromJson(Map<String, dynamic> json) {
    // Safely parse id
    int parsedId;
    try {
      if (json['id'] is int) {
        parsedId = json['id'] as int;
      } else if (json['id'] is String) {
        parsedId = int.parse(json['id'] as String);
      } else {
        parsedId = int.tryParse(json['id'].toString()) ?? 0;
      }
    } catch (e) {
      print('⚠️ StockOrderItemModel: Error parsing id: ${json['id']}, error: $e');
      parsedId = 0;
    }
    
    return StockOrderItemModel(
      id: parsedId,
      itemId: json['item_id'] is int 
          ? json['item_id'] 
          : json['item_id'] != null 
              ? int.tryParse(json['item_id'].toString()) 
              : null,
      itemName: (json['item'] is Map && json['item'] != null ? (json['item'] as Map)['name']?.toString() : null) ?? 
                (json['item'] is Map && json['item'] != null ? (json['item'] as Map)['item_name']?.toString() : null) ??
                json['item_name']?.toString(),
      quantity: json['qty'] != null
          ? (json['qty'] is double 
              ? json['qty'] 
              : double.tryParse(json['qty'].toString()) ?? 0.0)
          : json['quantity'] != null 
              ? (json['quantity'] is double 
                  ? json['quantity'] 
                  : double.tryParse(json['quantity'].toString()) ?? 0.0) 
              : json['qty_required'] != null
                  ? (json['qty_required'] is double
                      ? json['qty_required']
                      : double.tryParse(json['qty_required'].toString()) ?? 0.0)
                  : 0.0,
      availableStock: json['available_stock'] != null
          ? (json['available_stock'] is double
              ? json['available_stock']
              : double.tryParse(json['available_stock'].toString()))
          : json['stock'] != null
              ? (json['stock'] is double
                  ? json['stock']
                  : double.tryParse(json['stock'].toString()))
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
      'available_stock': availableStock,
    };
  }
}

