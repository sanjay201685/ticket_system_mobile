class PurchaseItemModel {
  int? itemId;
  double qtyRequired;
  double unitPrice;
  double? gstPercent;  // GST percentage (0-100)

  PurchaseItemModel({
    this.itemId,
    this.qtyRequired = 0.0,
    this.unitPrice = 0.0,
    this.gstPercent,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'qty_required': qtyRequired,
      'est_unit_price': unitPrice,
      if (gstPercent != null && gstPercent! > 0) 'gst_percent': gstPercent,
    };
  }

  bool isValid() {
    return itemId != null &&
           qtyRequired > 0 &&
           unitPrice > 0;
  }
}



