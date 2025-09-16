import '../entities/staff_entity.dart';

class StaffModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatar;
  final bool isActive;

  StaffModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatar,
    required this.isActive,
  });

  factory StaffModel.fromEntity(StaffEntity e) {
    return StaffModel(
      id: e.id,
      email: e.email,
      name: e.name ?? e.email,
      phone: e.phone,
      avatar: e.avatar,
      isActive: e.isActive,
    );
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      isActive: json['isActive'] == true,
    );
  }
}
