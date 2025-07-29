class UserEntity {
  final String id;
  final String username;
  final String? name;
  final String? email;
  final String? phone;
  final String role;
  final String? imageUrl;
  final StaffProfileEntity? staffProfile;

  UserEntity({
    required this.id,
    required this.username,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.imageUrl,
    this.staffProfile,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StaffProfileEntity {
  final String? staffCode;
  final String? status;
  final String? position;
  final String? shiftType;
  final String? workLocation;
  final String? address;
  final String? gender;
  final String? dob;
  final String? joinDate;

  StaffProfileEntity({
    this.staffCode,
    this.status,
    this.position,
    this.shiftType,
    this.workLocation,
    this.address,
    this.gender,
    this.dob,
    this.joinDate,
  });
}
