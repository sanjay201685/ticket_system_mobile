class OrderModel {
  final int id;
  final String? orderNumber;
  final String? vendorType;
  final int? vendorId;
  final String? vendorName;
  final String? purchaseMode;
  final String? priority;
  final String? status;
  final DateTime? createdAt;
  final DateTime? requiredByDate;
  final double? totalAmount;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    this.orderNumber,
    this.vendorType,
    this.vendorId,
    this.vendorName,
    this.purchaseMode,
    this.priority,
    this.status,
    this.createdAt,
    this.requiredByDate,
    this.totalAmount,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      orderNumber: json['order_number']?.toString(),
      vendorType: json['vendor_type']?.toString(),
      vendorId: json['vendor_id'] is int 
          ? json['vendor_id'] 
          : json['vendor_id'] != null 
              ? int.tryParse(json['vendor_id'].toString()) 
              : null,
      vendorName: json['vendor_name']?.toString(),
      purchaseMode: json['purchase_mode']?.toString(),
      priority: json['priority']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      requiredByDate: json['required_by_date'] != null 
          ? DateTime.tryParse(json['required_by_date'].toString()) 
          : null,
      totalAmount: json['total_amount'] != null 
          ? (json['total_amount'] is double 
              ? json['total_amount'] 
              : double.tryParse(json['total_amount'].toString())) 
          : null,
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List)
              .map((item) => OrderItemModel.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'vendor_type': vendorType,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'purchase_mode': purchaseMode,
      'priority': priority,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'required_by_date': requiredByDate?.toIso8601String(),
      'total_amount': totalAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderItemModel {
  final int id;
  final int? itemId;
  final String? itemName;
  final double qtyRequired;
  final double unitPrice;
  final double? totalPrice;

  OrderItemModel({
    required this.id,
    this.itemId,
    this.itemName,
    required this.qtyRequired,
    required this.unitPrice,
    this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      itemId: json['item_id'] is int 
          ? json['item_id'] 
          : json['item_id'] != null 
              ? int.tryParse(json['item_id'].toString()) 
              : null,
      itemName: json['item_name']?.toString(),
      qtyRequired: json['qty_required'] != null 
          ? (json['qty_required'] is double 
              ? json['qty_required'] 
              : double.tryParse(json['qty_required'].toString()) ?? 0.0) 
          : 0.0,
      unitPrice: json['unit_price'] != null || json['est_unit_price'] != null
          ? (json['unit_price'] ?? json['est_unit_price'] is double 
              ? (json['unit_price'] ?? json['est_unit_price']) 
              : double.tryParse((json['unit_price'] ?? json['est_unit_price']).toString()) ?? 0.0) 
          : 0.0,
      totalPrice: json['total_price'] != null 
          ? (json['total_price'] is double 
              ? json['total_price'] 
              : double.tryParse(json['total_price'].toString())) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'item_name': itemName,
      'qty_required': qtyRequired,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }
}

