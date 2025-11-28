class ItemModel {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final String? unit;
  final double? price;

  ItemModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.unit,
    this.price,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? 
            json['item_name']?.toString() ?? 
            '',
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      unit: json['unit']?.toString(),
      price: json['price'] != null 
          ? (json['price'] is double 
              ? json['price'] 
              : double.tryParse(json['price'].toString()) ?? 0.0)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'unit': unit,
      'price': price,
    };
  }

  @override
  String toString() => name;
}







