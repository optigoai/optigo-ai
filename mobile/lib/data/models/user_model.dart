class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? organizationId;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.organizationId,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String? ?? 'user',
      organizationId: json['organization_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'role': role,
    'organization_id': organizationId,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}

class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
