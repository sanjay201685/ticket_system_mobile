class PurchaseRequestModel {
  final int id;
  final String? requestNo;
  final String? technicianName;
  final String? vendorName;
  final String? vendorType;
  final String? priority;
  final double? totalAmount;
  final String? status;  // Status string (for backward compatibility)
  final Map<String, dynamic>? statusObj;  // Status object with key and name
  final DateTime? createdAt;
  final DateTime? requiredByDate;
  final String? paymentMode;
  final String? createdByName;
  final int? createdById;
  final List<PurchaseRequestItemModel> items;

  PurchaseRequestModel({
    required this.id,
    this.requestNo,
    this.technicianName,
    this.vendorName,
    this.vendorType,
    this.priority,
    this.totalAmount,
    this.status,
    this.statusObj,
    this.createdAt,
    this.requiredByDate,
    this.paymentMode,
    this.createdByName,
    this.createdById,
    this.items = const [],
  });

  factory PurchaseRequestModel.fromJson(Map<String, dynamic> json) {
    // Calculate total amount from items
    double? totalAmount;
    if (json['items'] != null && json['items'] is List) {
      double total = 0.0;
      for (var item in json['items'] as List) {
        if (item is Map) {
          final lineTotal = item['est_line_total'];
          if (lineTotal != null) {
            total += lineTotal is double 
                ? lineTotal 
                : (double.tryParse(lineTotal.toString()) ?? 0.0);
          }
        }
      }
      totalAmount = total > 0 ? total : null;
    } else if (json['total_amount'] != null) {
      totalAmount = json['total_amount'] is double 
          ? json['total_amount'] 
          : double.tryParse(json['total_amount'].toString());
    }

    return PurchaseRequestModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      requestNo: json['request_no']?.toString(),
      technicianName: json['creator']?['name']?.toString() ?? 
                      json['technician_name']?.toString() ?? 
                      json['created_by_name']?.toString() ??
                      json['user']?['name']?.toString(),
      vendorName: json['vendor']?['name']?.toString() ?? 
                  json['vendor_name']?.toString(),
      vendorType: (json['vendor_type'] is Map 
                      ? (json['vendor_type']?['key']?.toString() ?? 
                         json['vendor_type']?['name']?.toString() ?? 
                         json['vendor_type']?['value']?.toString())
                      : json['vendor_type']?.toString()) ??
                  json['vendor_type_name']?.toString() ??
                  json['vendor_type_key']?.toString(),
      priority: json['priority']?['key']?.toString() ?? 
                json['priority']?['name']?.toString() ??
                json['priority']?.toString() ?? 
                json['priority_name']?.toString(),
      totalAmount: totalAmount,
      status: json['status']?['key']?.toString() ?? 
              json['status']?['name']?.toString() ??
              json['status']?.toString(),
      statusObj: json['status'] is Map ? json['status'] as Map<String, dynamic> : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      requiredByDate: json['required_by_date'] != null 
          ? DateTime.tryParse(json['required_by_date'].toString()) 
          : null,
      paymentMode: json['payment_option']?['key']?.toString() ?? 
                   json['payment_option']?['name']?.toString() ??
                   json['payment_mode']?.toString(),
      createdByName: json['creator']?['name']?.toString() ?? 
                     json['created_by_name']?.toString() ??
                     json['user']?['name']?.toString(),
      createdById: json['created_by'] is int 
          ? json['created_by'] 
          : json['created_by'] != null 
              ? int.tryParse(json['created_by'].toString()) 
              : (json['created_by_id'] is int 
                  ? json['created_by_id'] 
                  : json['created_by_id'] != null 
                      ? int.tryParse(json['created_by_id'].toString()) 
                      : null),
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List)
              .map((item) => PurchaseRequestItemModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'request_no': requestNo,
      'technician_name': technicianName,
      'vendor_name': vendorName,
      'vendor_type': vendorType,
      'priority': priority,
      'total_amount': totalAmount,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'required_by_date': requiredByDate?.toIso8601String(),
      'payment_mode': paymentMode,
      'created_by_name': createdByName,
      'created_by_id': createdById,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class PurchaseRequestItemModel {
  final int id;
  final int? itemId;
  final String? itemName;
  final double qtyRequired;
  final double unitPrice;
  final double? totalPrice;
  final double? gstPercent;

  PurchaseRequestItemModel({
    required this.id,
    this.itemId,
    this.itemName,
    required this.qtyRequired,
    required this.unitPrice,
    this.totalPrice,
    this.gstPercent,
  });

  factory PurchaseRequestItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseRequestItemModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      itemId: json['item_id'] is int 
          ? json['item_id'] 
          : json['item_id'] != null 
              ? int.tryParse(json['item_id'].toString()) 
              : null,
      itemName: json['item']?['item_name']?.toString() ?? 
                json['item']?['name']?.toString() ??
                json['item_name']?.toString(),
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
      totalPrice: json['est_line_total'] != null
          ? (json['est_line_total'] is double 
              ? json['est_line_total'] 
              : double.tryParse(json['est_line_total'].toString()))
          : (json['total_price'] != null 
              ? (json['total_price'] is double 
                  ? json['total_price'] 
                  : double.tryParse(json['total_price'].toString())) 
              : null),
      gstPercent: json['gst_percent'] != null 
          ? (json['gst_percent'] is double 
              ? json['gst_percent'] 
              : double.tryParse(json['gst_percent'].toString())) 
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
      'gst_percent': gstPercent,
    };
  }
}

