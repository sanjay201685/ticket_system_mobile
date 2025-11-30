class StockOrderModel {
  final int id;
  final String? orderNo;
  final String? createdByName;
  final String? createdByRole;
  final String? status;
  final int totalItems;
  final DateTime? createdAt;

  StockOrderModel({
    required this.id,
    this.orderNo,
    this.createdByName,
    this.createdByRole,
    this.status,
    required this.totalItems,
    this.createdAt,
  });

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
      createdByName: json['created_by']?['name']?.toString() ?? 
                     json['created_by_name']?.toString() ??
                     json['creator']?['name']?.toString() ??
                     json['user']?['name']?.toString(),
      createdByRole: json['created_by']?['role']?.toString() ?? 
                     json['created_by_role']?.toString() ??
                     json['creator']?['role']?.toString(),
      status: json['status']?['key']?.toString() ?? 
              json['status']?['name']?.toString() ??
              json['status']?.toString(),
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
    );
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
    };
  }
}

class StockOrderItemModel {
  final int id;
  final int? itemId;
  final String? itemName;
  final double quantity;

  StockOrderItemModel({
    required this.id,
    this.itemId,
    this.itemName,
    required this.quantity,
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
      itemName: json['item']?['name']?.toString() ?? 
                json['item']?['item_name']?.toString() ??
                json['item_name']?.toString(),
      quantity: json['quantity'] != null 
          ? (json['quantity'] is double 
              ? json['quantity'] 
              : double.tryParse(json['quantity'].toString()) ?? 0.0) 
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'quantity': quantity,
    };
  }
}

