class UserResponse {
  const UserResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.enabled,
    required this.accountNonLocked,
    required this.roles,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool enabled;
  final bool accountNonLocked;
  final List<String> roles;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => roles.contains('ADMIN');

  factory UserResponse.fromJson(Map<String, dynamic> json) => UserResponse(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    enabled: json['enabled'] as bool,
    accountNonLocked: json['accountNonLocked'] as bool,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
    permissions: (json['permissions'] as List<dynamic>).cast<String>(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'enabled': enabled,
    'accountNonLocked': accountNonLocked,
    'roles': roles,
    'permissions': permissions,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}
