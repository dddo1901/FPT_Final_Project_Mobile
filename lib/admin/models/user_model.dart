import 'package:fpt_final_project_mobile/admin/entities/user_entity.dart';
import 'package:fpt_final_project_mobile/admin/models/staff_profile_model.dart';

class UserModel extends UserEntity {
  final StaffProfileModel? staffProfile;

  UserModel({
    required super.id,
    required super.username,
    required super.name,
    required super.email,
    required super.phone,
    required super.role,
    super.imageUrl,
    this.staffProfile,
  });

  /// Parse JSON → UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // ép int/string → String cho id
      id: json['id'].toString(),
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      imageUrl: json['imageUrl'] as String?,
      staffProfile: json['staffProfile'] != null
          ? StaffProfileModel.fromJson(
              json['staffProfile'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Serialize UserModel → JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id, // id đã là String rồi
      'username': username,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'imageUrl': imageUrl,
      // Nếu staffProfile null thì JSON cũng null
      'staffProfile': staffProfile?.toJson(),
    };
  }
}
