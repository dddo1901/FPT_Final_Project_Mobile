class UserEntity {
  final String id;
  final String username;
  final String name;
  final String email;
  final String phone;
  final String? imageUrl;
  final String role;
  final bool isActive;

  UserEntity({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.phone,
    this.imageUrl,
    required this.role,
    required this.isActive,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
