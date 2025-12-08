class SupplierModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;

  SupplierModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? 
            json['supplier_name']?.toString() ?? 
            '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }

  @override
  String toString() => name;
}









