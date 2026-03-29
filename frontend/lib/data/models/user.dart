enum UserRole {
  client,
  franchisee,
  production,
}

extension UserRoleX on UserRole {
  String get value {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.franchisee:
        return 'franchisee';
      case UserRole.production:
        return 'production';
    }
  }

  static UserRole fromValue(String raw) {
    switch (raw.toLowerCase()) {
      case 'client':
        return UserRole.client;
      case 'franchisee':
        return UserRole.franchisee;
      case 'production':
        return UserRole.production;
      default:
        throw ArgumentError('Unsupported role: $raw');
    }
  }
}

class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.productionType,
    required this.specialization,
    required this.franchiseId,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _stringValue(json['id']),
      email: _stringValue(json['email']),
      fullName: _stringValue(json['full_name']),
      role: UserRoleX.fromValue(_stringValue(json['role'])),
      productionType: _nullableStringValue(json['production_type']),
      specialization: _nullableStringValue(json['specialization']),
      franchiseId: json['franchise_id']?.toString(),
      createdAt: _stringValue(json['created_at']),
    );
  }

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? productionType;
  final String? specialization;
  final String? franchiseId;
  final String createdAt;

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? productionType,
    String? specialization,
    String? franchiseId,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      productionType: productionType ?? this.productionType,
      specialization: specialization ?? this.specialization,
      franchiseId: franchiseId ?? this.franchiseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'production_type': productionType,
      'specialization': specialization,
      'franchise_id': franchiseId,
      'created_at': createdAt,
    };
  }
}

String _stringValue(dynamic value) => value?.toString() ?? '';
String? _nullableStringValue(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) {
    return null;
  }
  return raw;
}
