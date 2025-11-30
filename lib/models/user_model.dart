class UserModel {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? role;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle date parsing with fallback
      DateTime parseDate(String? dateStr) {
        if (dateStr == null || dateStr.isEmpty) {
          return DateTime.now();
        }
        try {
          return DateTime.parse(dateStr);
        } catch (e) {
          return DateTime.now();
        }
      }

      // Handle role - can be string or object with 'name'/'key'
      String? roleValue;
      if (json['role'] != null) {
        if (json['role'] is String) {
          roleValue = json['role'] as String;
        } else if (json['role'] is Map) {
          final roleMap = json['role'] as Map;
          roleValue = roleMap['name']?.toString() ?? 
                     roleMap['key']?.toString() ?? 
                     roleMap['value']?.toString();
        }
      }

      return UserModel(
        id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name']?.toString() ?? json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        emailVerifiedAt: json['email_verified_at']?.toString(),
        role: roleValue,
        createdAt: parseDate(json['created_at']?.toString()),
        updatedAt: parseDate(json['updated_at']?.toString()),
      );
    } catch (e) {
      throw Exception('Failed to parse UserModel: $e. JSON: $json');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Check if user can approve/reject purchase requests
  bool get canApprovePurchaseRequests {
    if (role == null) {
      print('⚠️ UserModel: Role is null, cannot approve');
      return false;
    }
    
    final userRole = role!.toLowerCase().trim();
    print('🔍 UserModel: Checking role "$userRole" for approval permissions');
    
    // Handle various role formats
    final canApprove = userRole == 'team_leader' || 
           userRole == 'team leader' ||
           userRole == 'teamleader' ||
           userRole == 'manager' || 
           userRole == 'cashier' ||
           userRole.contains('team_leader') ||
           userRole.contains('team leader') ||
           userRole.contains('manager') ||
           userRole.contains('cashier');
    
    print('✅ UserModel: canApprovePurchaseRequests = $canApprove for role "$userRole"');
    return canApprove;
  }
}



















