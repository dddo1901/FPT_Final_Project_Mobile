class StaffEntity {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? avatar;
  final String role;
  final bool isActive;

  StaffEntity({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatar,
    required this.role,
    required this.isActive,
  });

  factory StaffEntity.fromJson(Map<String, dynamic> json) {
    return StaffEntity(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      role: json['role']?.toString() ?? 'STAFF',
      isActive: json['isActive'] == true,
    );
  }
}
