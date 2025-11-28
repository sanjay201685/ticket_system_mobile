class DropdownModel {
  final int id;
  final String name;
  final String? value;
  final String? code;

  DropdownModel({
    required this.id,
    required this.name,
    this.value,
    this.code,
  });

  factory DropdownModel.fromJson(Map<String, dynamic> json) {
    print('  Parsing DropdownModel from JSON: $json');
    final id = json['id'] is int ? json['id'] : int.parse(json['id'].toString());
    final name = json['name']?.toString() ?? 
            json['title']?.toString() ?? 
            json['label']?.toString() ?? 
            '';
    final value = json['value']?.toString();
    final code = json['code']?.toString();
    
    print('  Parsed: id=$id, name=$name, value=$value, code=$code');
    
    return DropdownModel(
      id: id,
      name: name,
      value: value,
      code: code,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
      'code': code,
    };
  }

  @override
  String toString() => name;
}


